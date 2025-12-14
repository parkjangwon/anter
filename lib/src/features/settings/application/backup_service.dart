import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';

import '../../../core/database/database.dart';
import '../../session/data/session_repository.dart';
import '../presentation/settings_provider.dart';
import '../presentation/shortcuts_provider.dart';

class BackupService {
  final Ref ref;

  BackupService(this.ref);

  Future<bool> exportBackup() async {
    try {
      // 1. Gather data
      final prefs = ref.read(sharedPreferencesProvider);
      final settingsJson = prefs.getString('app_settings');
      final shortcutsJson = prefs.getString('app_shortcuts');

      final sessions = await ref.read(sessionRepositoryProvider.future);

      // Fetch commands
      final db = ref.read(databaseProvider);
      final allCommands = await db.select(db.sessionCommands).get();

      // Group commands by session ID
      final commandsBySession = <int, List<SessionCommand>>{};
      for (final cmd in allCommands) {
        commandsBySession.putIfAbsent(cmd.sessionId, () => []).add(cmd);
      }

      final sessionsJson = sessions.map((s) {
        final json = s.toJson();
        final cmds = commandsBySession[s.id];
        if (cmds != null) {
          json['commands'] = cmds.map((c) => c.toJson()).toList();
        }
        return json;
      }).toList();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'settings': settingsJson != null ? jsonDecode(settingsJson) : null,
        'shortcuts': shortcutsJson != null ? jsonDecode(shortcutsJson) : null,
        'sessions': sessionsJson,
      };

      // 2. Save to file
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMddHHmm');
      final timestamp = formatter.format(now);
      final fileName = 'anter_backup_$timestamp.json';

      final jsonBytes = utf8.encode(jsonEncode(backupData));

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup',
        fileName: fileName,
        allowedExtensions: ['json'],
        type: FileType.custom,
        bytes: Uint8List.fromList(jsonBytes), // Required for Android/iOS/Web
      );

      if (outputFile != null) {
        // file_picker handles writing on Mobile/Web if bytes are provided.
        // On Desktop, we must write manually.
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          final file = File(outputFile);
          await file.writeAsBytes(jsonBytes);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Backup export failed: $e');
      return false;
    }
  }

  Future<void> importBackup() async {
    try {
      // 1. Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Backup File',
        type: FileType.custom,
        allowedExtensions: ['json', 'zip'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        Map<String, dynamic> data;

        // Legacy Support: If ZIP, try to find metadata
        if (path.toLowerCase().endsWith('.zip')) {
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          final metadataFile = archive.findFile('anter_backup_metadata.json');
          if (metadataFile == null)
            throw Exception('Invalid backup: metadata missing');
          final jsonStr = utf8.decode(metadataFile.content as List<int>);
          data = jsonDecode(jsonStr);
        } else {
          // Standard JSON
          final content = await file.readAsString();
          data = jsonDecode(content);
        }

        // 2. Restore Settings
        if (data['settings'] != null) {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setString('app_settings', jsonEncode(data['settings']));
          ref.invalidate(settingsProvider);
        }

        // 3. Restore Shortcuts
        if (data['shortcuts'] != null) {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setString('app_shortcuts', jsonEncode(data['shortcuts']));
          ref.invalidate(shortcutsProvider);
        }

        // 4. Restore Sessions
        if (data['sessions'] != null) {
          final sessionsList = data['sessions'] as List;
          final db = ref.read(databaseProvider);

          // Get current sessions to check for duplicates
          final currentSessions = await db.select(db.sessions).get();

          for (final s in sessionsList) {
            final sessionMap = s as Map<String, dynamic>;
            final sessionData = Session.fromJson(sessionMap);

            // Check for duplicate (same host, port, username)
            // Note: We skip 'password' check as it might be changed/empty
            final existingSession = currentSessions.cast<Session?>().firstWhere(
              (cs) =>
                  cs != null &&
                  cs.host == sessionData.host &&
                  cs.port == sessionData.port &&
                  cs.username == sessionData.username,
              orElse: () => null,
            );

            if (existingSession != null) {
              print(
                'Skipping duplicate session: ${sessionData.name} (ID: ${sessionData.id} -> ${existingSession.id})',
              );
            } else {
              // New session: Insert
              final companion = SessionsCompanion(
                // Leave ID undefined to let DB auto-increment
                name: drift.Value(sessionData.name),
                host: drift.Value(sessionData.host),
                port: drift.Value(sessionData.port),
                username: drift.Value(sessionData.username),
                password: drift.Value(sessionData.password),
                privateKeyPath: drift.Value(sessionData.privateKeyPath),
                passphrase: drift.Value(sessionData.passphrase),
                tag: drift.Value(sessionData.tag),
                loginScript: drift.Value(sessionData.loginScript),
                executeLoginScript: drift.Value(sessionData.executeLoginScript),
                proxyJumpId: drift.Value(sessionData.proxyJumpId),
                enableAgentForwarding: drift.Value(
                  sessionData.enableAgentForwarding,
                ),
                notificationKeywords: drift.Value(
                  sessionData.notificationKeywords,
                ),
                safetyLevel: drift.Value(sessionData.safetyLevel),
                createdAt: drift.Value(sessionData.createdAt),
                updatedAt: drift.Value(sessionData.updatedAt),
                keepaliveInterval: drift.Value(sessionData.keepaliveInterval),
                terminalType: drift.Value(sessionData.terminalType),
                backspaceMode: drift.Value(sessionData.backspaceMode),
              );

              final newSessionId = await db.into(db.sessions).insert(companion);

              // Restore Commands if any
              if (sessionMap.containsKey('commands') &&
                  sessionMap['commands'] != null) {
                final commandsList = sessionMap['commands'] as List;
                for (final c in commandsList) {
                  // We can't reuse ID, so we create new
                  final cmdMap = c as Map<String, dynamic>;
                  // Handle potential missing fields if corrupted, but assume valid
                  final label = cmdMap['label'] as String;
                  final command = cmdMap['command'] as String;
                  final sortOrder = cmdMap['sortOrder'] as int? ?? 0;

                  await db
                      .into(db.sessionCommands)
                      .insert(
                        SessionCommandsCompanion.insert(
                          sessionId: newSessionId,
                          label: label,
                          command: command,
                          sortOrder: drift.Value(sortOrder),
                        ),
                      );
                }
              }
            }
          }
          // Refresh session list
          ref.invalidate(sessionRepositoryProvider);
        }

        // 5. Explicitly Ignore Recordings as per user request
      }
    } catch (e) {
      print('Backup import failed: $e');
      rethrow;
    }
  }
}

final backupServiceProvider = Provider((ref) => BackupService(ref));
