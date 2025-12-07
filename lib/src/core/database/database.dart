import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Sessions, Groups])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          // Add login script columns
          await migrator.addColumn(sessions, sessions.loginScript);
          await migrator.addColumn(sessions, sessions.executeLoginScript);
        }
        if (from < 3) {
          // Add tag column
          await migrator.addColumn(sessions, sessions.tag);
        }
        if (from < 4) {
          // Add safetyLevel column
          await migrator.addColumn(sessions, sessions.safetyLevel);
        }
        if (from < 5) {
          // Add smartTunnelPorts column
          await migrator.addColumn(sessions, sessions.smartTunnelPorts);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'anter.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  return AppDatabase();
}
