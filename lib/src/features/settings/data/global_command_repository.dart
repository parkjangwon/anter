import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database.dart';
import '../../../core/database/tables.dart';

class GlobalCommandRepository {
  final AppDatabase db;

  GlobalCommandRepository(this.db);

  Stream<List<GlobalCommand>> watchCommands() {
    return (db.select(db.globalCommands)..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.id),
        ]))
        .watch();
  }

  Future<void> addCommand(String label, String command) async {
    // Get max sort order
    final maxOrder =
        await (db.selectOnly(db.globalCommands)
              ..addColumns([db.globalCommands.sortOrder.max()]))
            .map((row) => row.read(db.globalCommands.sortOrder.max()))
            .getSingle();

    await db
        .into(db.globalCommands)
        .insert(
          GlobalCommandsCompanion.insert(
            label: label,
            command: command,
            sortOrder: Value((maxOrder ?? -1) + 1),
          ),
        );
  }

  Future<void> updateCommand(int id, String label, String command) async {
    await (db.update(db.globalCommands)..where((t) => t.id.equals(id))).write(
      GlobalCommandsCompanion(label: Value(label), command: Value(command)),
    );
  }

  Future<void> deleteCommand(int id) async {
    await (db.delete(db.globalCommands)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderCommands(List<int> newOrder) async {
    await db.transaction(() async {
      for (int i = 0; i < newOrder.length; i++) {
        await (db.update(db.globalCommands)
              ..where((t) => t.id.equals(newOrder[i])))
            .write(GlobalCommandsCompanion(sortOrder: Value(i)));
      }
    });
  }
}

final globalCommandRepositoryProvider = Provider<GlobalCommandRepository>((
  ref,
) {
  return GlobalCommandRepository(ref.watch(databaseProvider));
});

final globalCommandsProvider = StreamProvider.autoDispose<List<GlobalCommand>>((
  ref,
) {
  return ref.watch(globalCommandRepositoryProvider).watchCommands();
});
