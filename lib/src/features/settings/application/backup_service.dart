import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import '../../session/data/session_repository.dart';
import '../presentation/settings_provider.dart';
import '../presentation/shortcuts_provider.dart';

import 'package:intl/intl.dart';

class BackupService {
  final Ref ref;

  BackupService(this.ref);

  Future<bool> exportBackup() async {
    // 1. Gather data
    final prefs = ref.read(sharedPreferencesProvider);
    final settingsJson = prefs.getString('app_settings');
    final shortcutsJson = prefs.getString('app_shortcuts');

    final sessions = await ref.read(sessionRepositoryProvider.future);
    final sessionsJson = sessions.map((s) => s.toJson()).toList();

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

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Backup',
      fileName: fileName,
      allowedExtensions: ['json'],
      type: FileType.custom,
    );

    if (outputFile != null) {
      final file = File(outputFile);
      await file.writeAsString(jsonEncode(backupData));
      return true;
    }
    return false;
  }

  Future<void> importBackup() async {
    // 1. Pick file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Backup File',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final data = jsonDecode(content);

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
        final repo = ref.read(sessionRepositoryProvider.notifier);

        for (final s in sessionsList) {
          final session = Session.fromJson(s as Map<String, dynamic>);

          final companion = SessionsCompanion(
            id: drift.Value(session.id),
            name: drift.Value(session.name),
            host: drift.Value(session.host),
            port: drift.Value(session.port),
            username: drift.Value(session.username),
            password: drift.Value(session.password),
            privateKeyPath: drift.Value(session.privateKeyPath),
            passphrase: drift.Value(session.passphrase),
            tag: drift.Value(session.tag),
            loginScript: drift.Value(session.loginScript),
            executeLoginScript: drift.Value(session.executeLoginScript),
            safetyLevel: drift.Value(session.safetyLevel),
            createdAt: drift.Value(session.createdAt),
            updatedAt: drift.Value(session.updatedAt),
          );

          await repo.upsert(companion);
        }
      }
    }
  }
}

final backupServiceProvider = Provider((ref) => BackupService(ref));
