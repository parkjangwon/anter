import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:drift/drift.dart';
import 'package:anter/src/core/database/database.dart';
import 'package:anter/src/core/database/tables.dart';

// part 'session_repository.g.dart';

final sessionRepositoryProvider =
    AsyncNotifierProvider<SessionRepository, List<Session>>(() {
      return SessionRepository();
    });

class SessionRepository extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final db = ref.watch(databaseProvider);
    return db.select(db.sessions).get();
  }

  Future<void> addSession(SessionsCompanion session) async {
    final db = ref.read(databaseProvider);
    await db.into(db.sessions).insert(session);
    ref.invalidateSelf();
  }

  Future<void> updateSession(SessionsCompanion session) async {
    final db = ref.read(databaseProvider);
    await db.update(db.sessions).replace(session);
    ref.invalidateSelf();
  }

  Future<void> upsert(SessionsCompanion session) async {
    final db = ref.read(databaseProvider);
    await db.into(db.sessions).insertOnConflictUpdate(session);
    ref.invalidateSelf();
  }

  Future<void> deleteSession(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.sessions)..where((t) => t.id.equals(id))).go();
    ref.invalidateSelf();
  }
}
