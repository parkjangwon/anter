import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:stream_channel/stream_channel.dart';
import '../../../core/database/database.dart';
import '../domain/script_step.dart';
import '../../session_recording/domain/session_recorder.dart';
import '../../../core/services/notification_service.dart';

class SSHService {
  final List<SSHClient> _clients = [];
  String _encoding = 'utf-8';
  final Map<int, ServerSocket> _activeForwards = {};

  // Debounce map: Keyword -> Last Notification Time
  final Map<String, DateTime> _lastNotificationTime = {};
  static const Duration _notificationCooldown = Duration(seconds: 5);

  SSHClient? get _client => _clients.isNotEmpty ? _clients.last : null;

  Future<int> startForwarding({required int remotePort, int? localPort}) async {
    if (_client == null) throw Exception('SSH client is not connected');

    try {
      final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        localPort ?? 0,
      );
      final actualLocalPort = server.port;

      print(
        'SSHService: Start forwarding local $actualLocalPort -> remote $remotePort',
      );

      server.listen((socket) async {
        try {
          final channel = await _client!.forwardLocal('localhost', remotePort);

          // Pipe socket -> channel
          socket.listen(
            (data) {
              // print('SSHService: Socket -> SSH (${data.length} bytes)');
              // SSHChannel should enable adding data directly if it implements StreamSink
              channel.sink.add(data);
            },
            onDone: () {
              print('SSHService: Socket done');
              channel.close();
            },
            onError: (e) {
              print('SSHService: Socket error: $e');
              socket.destroy();
            },
          );

          // Pipe channel -> socket
          channel.stream.listen(
            (data) {
              // print('SSHService: SSH -> Socket (${data.length} bytes)');
              socket.add(data);
            },
            onDone: () {
              print('SSHService: SSH Channel done');
              socket.close();
            },
            onError: (e) {
              print('SSHService: SSH Channel error: $e');
              socket.destroy();
            },
          );
        } catch (e) {
          print('SSHService: Forwarding error: $e');
          socket.destroy();
        }
      });

      _activeForwards[actualLocalPort] = server;
      return actualLocalPort;
    } catch (e) {
      print('SSHService: Failed to start forwarding: $e');
      rethrow;
    }
  }

  Future<void> stopForwarding(int localPort) async {
    final server = _activeForwards.remove(localPort);
    if (server != null) {
      await server.close();
      print('SSHService: Stopped forwarding local $localPort');
    }
  }

  SessionRecorder? _recorder;

  void setRecorder(SessionRecorder? recorder) {
    _recorder = recorder;
  }

  Future<void> connect({
    required List<Session> hops,
    required Terminal terminal,
    SessionRecorder? recorder,
    String encoding = 'utf-8',
  }) async {
    _encoding = encoding;
    if (recorder != null) _recorder = recorder;

    // Clear previous clients if any
    dispose();

    print(
      'SSHService: connect called for chain: ${hops.map((s) => s.host).join(' -> ')}',
    );
    try {
      for (int i = 0; i < hops.length; i++) {
        final session = hops[i];
        terminal.write('Connecting to ${session.host}:${session.port}...\r\n');

        dynamic socket;

        if (i == 0) {
          socket = await SSHSocket.connect(session.host, session.port);
        } else {
          // Tunnel through previous client
          final previousClient = _clients.last;
          terminal.write('  via ${hops[i - 1].host}...\r\n');
          // forwardLocal opens a direct-tcpip channel to the target
          // Using dynamic to bypass strict analyzer check as SSHChannel usually implements what's needed
          // or SSHClient constructor is flexible enough at runtime.
          final dynamic forwardChannel = await previousClient.forwardLocal(
            session.host,
            session.port,
          );
          socket = forwardChannel as StreamChannel<List<int>>;
        }

        print('SSHService: Socket connected for ${session.host}');

        final identities = session.privateKeyPath != null
            ? await _loadIdentity(
                session.privateKeyPath!,
                session.passphrase,
                terminal,
              )
            : <SSHKeyPair>[];

        final client = SSHClient(
          socket as dynamic,
          username: session.username,
          onPasswordRequest: () {
            if (session.password != null) return session.password!;
            terminal.write(
              'Password required for ${session.host} but not provided.\r\n',
            );
            return '';
          },
          identities: identities,
        );

        _clients.add(client);

        terminal.write('Connected to ${session.host}. Authenticating...\r\n');
        await client.authenticated;
        terminal.write('Authenticated to ${session.host}.\r\n');
      }

      // Setup shell on the final client
      final session = _clients.last;
      final targetSessionData = hops.last;

      print('SSHService: All hops connected. Starting shell.');

      final shell = await session.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );

      print('SSHService: Shell session started');

      terminal.buffer.clear();

      // Pipe stdout/stderr to terminal with encoding conversion
      shell.stdout.listen((data) async {
        final decoded = await _decodeWithEncoding(data);
        terminal.write(decoded);
        _recorder?.write(decoded);

        // Keyword monitoring
        if (targetSessionData.notificationKeywords != null) {
          // print('DEBUG: Checking keywords for chunk: "${decoded.replaceAll('\n', '\\n')}"');
          _checkKeywords(decoded, targetSessionData);
        }
      });

      shell.stderr.listen((data) async {
        final decoded = await _decodeWithEncoding(data);
        terminal.write(decoded);
        _recorder?.write(decoded);
      });

      // Pipe terminal input to stdin with encoding conversion
      terminal.onOutput = (data) async {
        // [Hotfix] Intercept control + tab input
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        if (isCtrl && (data == '\t' || data.codeUnits.contains(9))) {
          return;
        }

        shell.write(await _encodeWithEncoding(data));
      };

      // Handle window resize
      terminal.onResize = (w, h, pw, ph) {
        shell.resizeTerminal(w, h, pw, ph);
      };

      // Execute login script if enabled (only for target)
      if (targetSessionData.executeLoginScript &&
          targetSessionData.loginScript != null &&
          targetSessionData.loginScript!.isNotEmpty) {
        await _executeLoginScript(
          shell,
          targetSessionData.loginScript!,
          terminal,
        );
      }

      print('SSHService: Setup complete');

      _handleSessionCompletion(shell, terminal);
    } catch (e) {
      print('SSHService: Error: $e');
      terminal.write('Error: $e\r\n');
      dispose(); // Close all
      rethrow;
    }
  }

  Future<void> _handleSessionCompletion(
    SSHSession session,
    Terminal terminal,
  ) async {
    try {
      await session.done;
      terminal.write('\r\nSession closed.\r\n');
    } catch (e) {
      terminal.write('Error: $e\r\n');
    } finally {
      dispose();
    }
  }

  Future<String> _decodeWithEncoding(List<int> data) async {
    try {
      if (_encoding == 'utf-8') {
        return utf8.decode(data, allowMalformed: true);
      }
      // Use charset_converter for other encodings
      final uint8Data = data is Uint8List ? data : Uint8List.fromList(data);
      return await CharsetConverter.decode(_encoding, uint8Data);
    } catch (e) {
      // Fallback to UTF-8 if conversion fails
      return utf8.decode(data, allowMalformed: true);
    }
  }

  Future<Uint8List> _encodeWithEncoding(String data) async {
    try {
      if (_encoding == 'utf-8') {
        return Uint8List.fromList(utf8.encode(data));
      }
      // Use charset_converter for other encodings
      return await CharsetConverter.encode(_encoding, data);
    } catch (e) {
      // Fallback to UTF-8 if conversion fails
      return Uint8List.fromList(utf8.encode(data));
    }
  }

  void dispose() {
    for (final client in _clients.reversed) {
      client.close();
    }
    _clients.clear();
  }

  Future<List<SSHKeyPair>> _loadIdentity(
    String privateKeyPath,
    String? passphrase,
    Terminal terminal,
  ) async {
    try {
      final file = File(privateKeyPath);
      if (!await file.exists()) {
        terminal.write('Private key file not found: $privateKeyPath\\r\\n');
        return [];
      }

      final keyContent = await file.readAsString();
      return SSHKeyPair.fromPem(keyContent, passphrase);
    } catch (e) {
      terminal.write('Failed to load private key: $e\\r\\n');
      return [];
    }
  }

  Future<void> _executeLoginScript(
    SSHSession session,
    String scriptJson,
    Terminal terminal,
  ) async {
    try {
      // Parse JSON script
      final script = LoginScript.fromJson(scriptJson);

      if (script.isEmpty) {
        return;
      }

      terminal.write(
        '\r\n[Executing login script with ${script.steps.length} steps...]\r\n',
      );

      // Buffer to accumulate terminal output
      final outputBuffer = StringBuffer();

      // Listen to session output
      final outputSubscription = session.stdout.listen((data) {
        final text = utf8.decode(data);
        outputBuffer.write(text);
      });

      try {
        for (var i = 0; i < script.steps.length; i++) {
          final step = script.steps[i];

          terminal.write(
            '[Step ${i + 1}/${script.steps.length}] Waiting for: "${step.keyword}"\r\n',
          );

          // Wait for keyword to appear in output
          final startTime = DateTime.now();
          const timeout = Duration(seconds: 30);

          while (!outputBuffer.toString().contains(step.keyword)) {
            await Future.delayed(const Duration(milliseconds: 100));

            if (DateTime.now().difference(startTime) > timeout) {
              terminal.write(
                '[Warning] Timeout waiting for "${step.keyword}", skipping...\r\n',
              );
              break;
            }
          }

          // Apply delay if specified
          if (step.delayMs > 0) {
            await Future.delayed(Duration(milliseconds: step.delayMs));
          }

          // Execute command
          if (step.command.isNotEmpty) {
            terminal.write('[Executing] ${step.command}\r\n');
            session.write(utf8.encode('${step.command}\n'));

            // Small delay to allow command to process
            await Future.delayed(const Duration(milliseconds: 200));
          }

          // Clear buffer for next step
          outputBuffer.clear();
        }

        terminal.write('[Login script completed successfully]\r\n\r\n');
      } finally {
        await outputSubscription.cancel();
      }
    } catch (e) {
      terminal.write('[Login script error: $e]\r\n');
    }
  }

  void _checkKeywords(String text, Session session) {
    if (session.notificationKeywords == null) return;

    try {
      final List<dynamic> keywordsInfo = jsonDecode(
        session.notificationKeywords!,
      );
      // print('DEBUG: Loaded keys: $keywordsInfo');

      for (final keyword in keywordsInfo) {
        if (keyword is! String) continue;

        bool matched = false;

        if (keyword.startsWith('r:')) {
          // Regex match
          try {
            final pattern = keyword.substring(2);
            final regex = RegExp(pattern);
            if (regex.hasMatch(text)) {
              print('DEBUG: Regex matched: $pattern');
              matched = true;
            }
          } catch (e) {
            print('Invalid regex keyword: $keyword');
          }
        } else {
          // Simple string match
          if (text.contains(keyword)) {
            print('DEBUG: String matched: $keyword');
            matched = true;
          }
        }

        if (matched) {
          _triggerNotification(session, keyword);
        }
      }
    } catch (e) {
      print('Error checking keywords: $e');
    }
  }

  void _triggerNotification(Session session, String keyword) {
    print('DEBUG: Triggering notification for $keyword');
    final now = DateTime.now();
    final lastTime = _lastNotificationTime[keyword];

    if (lastTime == null || now.difference(lastTime) > _notificationCooldown) {
      _lastNotificationTime[keyword] = now;

      print('DEBUG: Notification cooldown passed. Showing notification.');
      NotificationService().showNotification(
        id: session.id + keyword.hashCode, // Unique ID per session+keyword
        title: 'Keyword Detect: ${session.name}',
        body: 'Found "$keyword" in terminal output.',
        payload: session.id.toString(),
      );
    } else {
      print('DEBUG: Notification skipped due to cooldown.');
    }
  }
}
