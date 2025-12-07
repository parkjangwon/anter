import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';

part 'session_recording_repository.g.dart';

@Riverpod(keepAlive: true)
SessionRecordingRepository sessionRecordingRepository(Ref ref) {
  return SessionRecordingRepository(ref.watch(databaseProvider));
}

final sessionRecordingsListProvider = StreamProvider<List<SessionRecording>>((
  ref,
) {
  return ref.watch(sessionRecordingRepositoryProvider).watchAll();
});

class SessionRecordingRepository {
  final AppDatabase _db;

  SessionRecordingRepository(this._db);

  Future<List<SessionRecording>> getAll() {
    return (_db.select(_db.sessionRecordings)..orderBy([
          (t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Stream<List<SessionRecording>> watchAll() {
    return (_db.select(_db.sessionRecordings)..orderBy([
          (t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<List<SessionRecording>> getBySessionId(int sessionId) {
    return (_db.select(_db.sessionRecordings)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<int> create({
    required int sessionId,
    required DateTime startTime,
    required String filePath,
  }) {
    return _db
        .into(_db.sessionRecordings)
        .insert(
          SessionRecordingsCompanion.insert(
            sessionId: sessionId,
            startTime: startTime,
            filePath: filePath,
          ),
        );
  }

  Future<void> updateEndTimeAndSize(int id, DateTime endTime, int size) {
    return (_db.update(
      _db.sessionRecordings,
    )..where((t) => t.id.equals(id))).write(
      SessionRecordingsCompanion(
        endTime: Value(endTime),
        fileSize: Value(size),
      ),
    );
  }

  Future<void> deleteRecording(int id) async {
    await (_db.delete(
      _db.sessionRecordings,
    )..where((t) => t.id.equals(id))).go();
  }
}
