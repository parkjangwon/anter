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
  IntColumn get proxyJumpId => integer().nullable().references(Sessions, #id)();
  BoolColumn get enableAgentForwarding =>
      boolean().withDefault(const Constant(false))();
  TextColumn get notificationKeywords =>
      text().nullable()(); // JSON list of strings/regex
  IntColumn get keepaliveInterval =>
      integer().withDefault(const Constant(60))(); // Seconds, 0 to disable
  TextColumn get terminalType =>
      text().withDefault(const Constant('xterm-256color'))();
  IntColumn get backspaceMode =>
      integer().withDefault(const Constant(0))(); // 0: DEL(127), 1: BS(8)
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

class SessionRecordings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(Sessions, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get filePath => text()(); // Path to the recording file
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get name => text().withLength(min: 1, max: 100).nullable()();
}

class GlobalCommands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text().withLength(min: 1, max: 20)();
  TextColumn get command => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class SessionCommands extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text().withLength(min: 1, max: 20)();
  TextColumn get command => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}
