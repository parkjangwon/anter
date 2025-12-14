import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/database/database.dart';

final sessionCommandRepositoryProvider =
    AsyncNotifierProvider<SessionCommandRepository, void>(() {
      return SessionCommandRepository();
    });

class SessionCommandRepository extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state needed, we fetch on demand
  }

  Future<List<SessionCommand>> getCommands(int sessionId) async {
    final db = ref.read(databaseProvider);
    final query = db.select(db.sessionCommands)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder),
        (t) => OrderingTerm(expression: t.id),
      ]);
    return query.get();
  }

  Future<void> addCommand(int sessionId, String label, String command) async {
    final db = ref.read(databaseProvider);

    // Get max sort order
    final query = db.select(db.sessionCommands)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.desc),
      ])
      ..limit(1);

    final lastCommand = await query.getSingleOrNull();
    final newOrder = (lastCommand?.sortOrder ?? -1) + 1;

    await db
        .into(db.sessionCommands)
        .insert(
          SessionCommandsCompanion.insert(
            sessionId: sessionId,
            label: label,
            command: command,
            sortOrder: Value(newOrder),
          ),
        );
    ref.invalidateSelf();
  }

  Future<void> updateCommand(int id, String label, String command) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.sessionCommands)..where((t) => t.id.equals(id))).write(
      SessionCommandsCompanion(label: Value(label), command: Value(command)),
    );
    ref.invalidateSelf();
  }

  Future<void> deleteCommand(int id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.sessionCommands)..where((t) => t.id.equals(id))).go();
    ref.invalidateSelf();
  }
}

// Provider to watch commands for a specific session
final sessionCommandsProvider = StreamProvider.autoDispose
    .family<List<SessionCommand>, int>((ref, sessionId) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.sessionCommands)
            ..where((t) => t.sessionId.equals(sessionId))
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .watch();
    });
