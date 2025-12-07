import 'package:drift/drift.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get host => text()();
  IntColumn get port => integer().withDefault(const Constant(22))();
  TextColumn get username => text()();
  TextColumn get password => text().nullable()(); // TODO: Encrypt this
  TextColumn get privateKeyPath => text().nullable()();
  TextColumn get passphrase => text().nullable()(); // For private key
  TextColumn get loginScript =>
      text().nullable()(); // Commands to execute after login
  BoolColumn get executeLoginScript =>
      boolean().withDefault(const Constant(false))();
  IntColumn get groupId => integer().nullable().references(Groups, #id)();
  TextColumn get tag => text().nullable()();
  // 0: None, 1: Yellow (Caution), 2: Red (Danger)
  IntColumn get safetyLevel => integer().withDefault(const Constant(0))();
  TextColumn get smartTunnelPorts =>
      text().nullable()(); // Comma separated ports
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get color => integer().nullable()(); // 0xAARRGGBB
  TextColumn get icon => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
