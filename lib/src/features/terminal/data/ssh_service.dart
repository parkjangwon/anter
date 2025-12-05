import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'package:charset_converter/charset_converter.dart';
import '../domain/script_step.dart';

class SSHService {
  SSHClient? _client;
  String _encoding = 'utf-8';

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? passphrase,
    required Terminal terminal,
    String? loginScript,
    bool executeLoginScript = false,
    String encoding = 'utf-8',
  }) async {
    _encoding = encoding;
    print(
      'SSHService: connect called for $host:$port with encoding $_encoding',
    );
    try {
      terminal.write('Connecting to $host:$port...\r\n');

      final socket = await SSHSocket.connect(host, port);
      print('SSHService: Socket connected');

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          if (password != null) return password;
          terminal.write('Password required but not provided.\r\n');
          return '';
        },
        identities: privateKeyPath != null
            ? await _loadIdentity(privateKeyPath, passphrase, terminal)
            : [],
      );

      terminal.write('Connected. Authenticating...\r\n');
      print('SSHService: Client created, waiting for authentication');
      await _client!.authenticated;
      terminal.write('Authenticated.\r\n');
      print('SSHService: Authenticated');

      final session = await _client!.shell(
        pty: SSHPtyConfig(
          width: terminal.viewWidth,
          height: terminal.viewHeight,
        ),
      );
      print('SSHService: Shell session started');

      terminal.buffer.clear();

      // Pipe stdout/stderr to terminal with encoding conversion
      session.stdout.listen((data) async {
        terminal.write(await _decodeWithEncoding(data));
      });

      session.stderr.listen((data) async {
        terminal.write(await _decodeWithEncoding(data));
      });

      // Pipe terminal input to stdin with encoding conversion
      terminal.onOutput = (data) async {
        // [Hotfix] Intercept control + tab input to prevent ghost characters
        // when using global shortcuts.
        final isCtrl = HardwareKeyboard.instance.isControlPressed;
        if (isCtrl && (data == '\t' || data.codeUnits.contains(9))) {
          return;
        }

        session.write(await _encodeWithEncoding(data));
      };

      // Handle window resize
      terminal.onResize = (w, h, pw, ph) {
        session.resizeTerminal(w, h, pw, ph);
      };

      // Execute login script if enabled
      if (executeLoginScript && loginScript != null && loginScript.isNotEmpty) {
        await _executeLoginScript(session, loginScript, terminal);
      }

      print('SSHService: Setup complete, waiting for session done');
      // We should NOT await session.done here, because that blocks createTab!
      // We want to return as soon as connection is established.
      // BUT the original code awaited session.done.
      // If we await session.done, createTab waits until the session ENDS.
      // This is WRONG. createTab should return once connected.

      // Wait, if we don't await session.done, we exit the try block.
      // And the finally block runs.
      // And _client?.close() runs.
      // So the connection closes immediately!

      // This is the bug!
      // The original code awaited session.done, which meant createTab blocked until session closed.
      // If createTab blocks, the UI waits.
      // But the UI is async?
      // onPressed awaits createTab.
      // So the button stays pressed until session closes?
      // No, onPressed is async, so it returns a Future.
      // But if createTab awaits session.done, the "await createTab" in onPressed waits forever (until session closes).
      // This means the code AFTER await createTab (if any) won't run.
      // But more importantly, does this block the UI?
      // No, it's async.

      // However, if createTab blocks, then state = state.copyWith(...) is NOT REACHED until session closes!
      // Look at createTab:
      // await service.connect(...)
      // state = state.copyWith(...)

      // If connect awaits session.done, then state is NOT updated until session closes.
      // So the tab is NOT added to the state until the session is closed!
      // This explains "no reaction". The tab is never added while the session is active.

      // Fix: SSHService.connect should NOT await session.done.
      // But we need to keep the client open.
      // So we cannot use try...finally to close the client.
      // We need to handle cleanup differently.

      // I will fix this logic now.

      _handleSessionCompletion(session, terminal);
    } catch (e) {
      print('SSHService: Error: $e');
      terminal.write('Error: $e\r\n');
      _client?.close();
      rethrow; // Rethrow so createTab knows it failed
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
      _client?.close();
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
    _client?.close();
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
}
