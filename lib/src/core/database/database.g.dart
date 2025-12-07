// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GroupsTable extends Groups with TableInfo<$GroupsTable, Group> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, color, icon, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<Group> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Group map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Group(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class Group extends DataClass implements Insertable<Group> {
  final int id;
  final String name;
  final int? color;
  final String? icon;
  final DateTime createdAt;
  const Group({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      createdAt: Value(createdAt),
    );
  }

  factory Group.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Group(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'icon': serializer.toJson<String?>(icon),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Group copyWith({
    int? id,
    String? name,
    Value<int?> color = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    DateTime? createdAt,
  }) => Group(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    createdAt: createdAt ?? this.createdAt,
  );
  Group copyWithCompanion(GroupsCompanion data) {
    return Group(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Group(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, color, icon, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Group &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.createdAt == this.createdAt);
}

class GroupsCompanion extends UpdateCompanion<Group> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<String?> icon;
  final Value<DateTime> createdAt;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GroupsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Group> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? icon,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? color,
    Value<String?>? icon,
    Value<DateTime>? createdAt,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(22),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _privateKeyPathMeta = const VerificationMeta(
    'privateKeyPath',
  );
  @override
  late final GeneratedColumn<String> privateKeyPath = GeneratedColumn<String>(
    'private_key_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _passphraseMeta = const VerificationMeta(
    'passphrase',
  );
  @override
  late final GeneratedColumn<String> passphrase = GeneratedColumn<String>(
    'passphrase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loginScriptMeta = const VerificationMeta(
    'loginScript',
  );
  @override
  late final GeneratedColumn<String> loginScript = GeneratedColumn<String>(
    'login_script',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _executeLoginScriptMeta =
      const VerificationMeta('executeLoginScript');
  @override
  late final GeneratedColumn<bool> executeLoginScript = GeneratedColumn<bool>(
    'execute_login_script',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("execute_login_script" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<int> groupId = GeneratedColumn<int>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _safetyLevelMeta = const VerificationMeta(
    'safetyLevel',
  );
  @override
  late final GeneratedColumn<int> safetyLevel = GeneratedColumn<int>(
    'safety_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _smartTunnelPortsMeta = const VerificationMeta(
    'smartTunnelPorts',
  );
  @override
  late final GeneratedColumn<String> smartTunnelPorts = GeneratedColumn<String>(
    'smart_tunnel_ports',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    host,
    port,
    username,
    password,
    privateKeyPath,
    passphrase,
    loginScript,
    executeLoginScript,
    groupId,
    tag,
    safetyLevel,
    smartTunnelPorts,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    }
    if (data.containsKey('private_key_path')) {
      context.handle(
        _privateKeyPathMeta,
        privateKeyPath.isAcceptableOrUnknown(
          data['private_key_path']!,
          _privateKeyPathMeta,
        ),
      );
    }
    if (data.containsKey('passphrase')) {
      context.handle(
        _passphraseMeta,
        passphrase.isAcceptableOrUnknown(data['passphrase']!, _passphraseMeta),
      );
    }
    if (data.containsKey('login_script')) {
      context.handle(
        _loginScriptMeta,
        loginScript.isAcceptableOrUnknown(
          data['login_script']!,
          _loginScriptMeta,
        ),
      );
    }
    if (data.containsKey('execute_login_script')) {
      context.handle(
        _executeLoginScriptMeta,
        executeLoginScript.isAcceptableOrUnknown(
          data['execute_login_script']!,
          _executeLoginScriptMeta,
        ),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('safety_level')) {
      context.handle(
        _safetyLevelMeta,
        safetyLevel.isAcceptableOrUnknown(
          data['safety_level']!,
          _safetyLevelMeta,
        ),
      );
    }
    if (data.containsKey('smart_tunnel_ports')) {
      context.handle(
        _smartTunnelPortsMeta,
        smartTunnelPorts.isAcceptableOrUnknown(
          data['smart_tunnel_ports']!,
          _smartTunnelPortsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      ),
      privateKeyPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_key_path'],
      ),
      passphrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passphrase'],
      ),
      loginScript: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}login_script'],
      ),
      executeLoginScript: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}execute_login_script'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_id'],
      ),
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      safetyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}safety_level'],
      )!,
      smartTunnelPorts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}smart_tunnel_ports'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKeyPath;
  final String? passphrase;
  final String? loginScript;
  final bool executeLoginScript;
  final int? groupId;
  final String? tag;
  final int safetyLevel;
  final String? smartTunnelPorts;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Session({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    this.password,
    this.privateKeyPath,
    this.passphrase,
    this.loginScript,
    required this.executeLoginScript,
    this.groupId,
    this.tag,
    required this.safetyLevel,
    this.smartTunnelPorts,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['port'] = Variable<int>(port);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    if (!nullToAbsent || privateKeyPath != null) {
      map['private_key_path'] = Variable<String>(privateKeyPath);
    }
    if (!nullToAbsent || passphrase != null) {
      map['passphrase'] = Variable<String>(passphrase);
    }
    if (!nullToAbsent || loginScript != null) {
      map['login_script'] = Variable<String>(loginScript);
    }
    map['execute_login_script'] = Variable<bool>(executeLoginScript);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<int>(groupId);
    }
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    map['safety_level'] = Variable<int>(safetyLevel);
    if (!nullToAbsent || smartTunnelPorts != null) {
      map['smart_tunnel_ports'] = Variable<String>(smartTunnelPorts);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      port: Value(port),
      username: Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      privateKeyPath: privateKeyPath == null && nullToAbsent
          ? const Value.absent()
          : Value(privateKeyPath),
      passphrase: passphrase == null && nullToAbsent
          ? const Value.absent()
          : Value(passphrase),
      loginScript: loginScript == null && nullToAbsent
          ? const Value.absent()
          : Value(loginScript),
      executeLoginScript: Value(executeLoginScript),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      safetyLevel: Value(safetyLevel),
      smartTunnelPorts: smartTunnelPorts == null && nullToAbsent
          ? const Value.absent()
          : Value(smartTunnelPorts),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      port: serializer.fromJson<int>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      privateKeyPath: serializer.fromJson<String?>(json['privateKeyPath']),
      passphrase: serializer.fromJson<String?>(json['passphrase']),
      loginScript: serializer.fromJson<String?>(json['loginScript']),
      executeLoginScript: serializer.fromJson<bool>(json['executeLoginScript']),
      groupId: serializer.fromJson<int?>(json['groupId']),
      tag: serializer.fromJson<String?>(json['tag']),
      safetyLevel: serializer.fromJson<int>(json['safetyLevel']),
      smartTunnelPorts: serializer.fromJson<String?>(json['smartTunnelPorts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'port': serializer.toJson<int>(port),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String?>(password),
      'privateKeyPath': serializer.toJson<String?>(privateKeyPath),
      'passphrase': serializer.toJson<String?>(passphrase),
      'loginScript': serializer.toJson<String?>(loginScript),
      'executeLoginScript': serializer.toJson<bool>(executeLoginScript),
      'groupId': serializer.toJson<int?>(groupId),
      'tag': serializer.toJson<String?>(tag),
      'safetyLevel': serializer.toJson<int>(safetyLevel),
      'smartTunnelPorts': serializer.toJson<String?>(smartTunnelPorts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Session copyWith({
    int? id,
    String? name,
    String? host,
    int? port,
    String? username,
    Value<String?> password = const Value.absent(),
    Value<String?> privateKeyPath = const Value.absent(),
    Value<String?> passphrase = const Value.absent(),
    Value<String?> loginScript = const Value.absent(),
    bool? executeLoginScript,
    Value<int?> groupId = const Value.absent(),
    Value<String?> tag = const Value.absent(),
    int? safetyLevel,
    Value<String?> smartTunnelPorts = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Session(
    id: id ?? this.id,
    name: name ?? this.name,
    host: host ?? this.host,
    port: port ?? this.port,
    username: username ?? this.username,
    password: password.present ? password.value : this.password,
    privateKeyPath: privateKeyPath.present
        ? privateKeyPath.value
        : this.privateKeyPath,
    passphrase: passphrase.present ? passphrase.value : this.passphrase,
    loginScript: loginScript.present ? loginScript.value : this.loginScript,
    executeLoginScript: executeLoginScript ?? this.executeLoginScript,
    groupId: groupId.present ? groupId.value : this.groupId,
    tag: tag.present ? tag.value : this.tag,
    safetyLevel: safetyLevel ?? this.safetyLevel,
    smartTunnelPorts: smartTunnelPorts.present
        ? smartTunnelPorts.value
        : this.smartTunnelPorts,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      privateKeyPath: data.privateKeyPath.present
          ? data.privateKeyPath.value
          : this.privateKeyPath,
      passphrase: data.passphrase.present
          ? data.passphrase.value
          : this.passphrase,
      loginScript: data.loginScript.present
          ? data.loginScript.value
          : this.loginScript,
      executeLoginScript: data.executeLoginScript.present
          ? data.executeLoginScript.value
          : this.executeLoginScript,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      tag: data.tag.present ? data.tag.value : this.tag,
      safetyLevel: data.safetyLevel.present
          ? data.safetyLevel.value
          : this.safetyLevel,
      smartTunnelPorts: data.smartTunnelPorts.present
          ? data.smartTunnelPorts.value
          : this.smartTunnelPorts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('privateKeyPath: $privateKeyPath, ')
          ..write('passphrase: $passphrase, ')
          ..write('loginScript: $loginScript, ')
          ..write('executeLoginScript: $executeLoginScript, ')
          ..write('groupId: $groupId, ')
          ..write('tag: $tag, ')
          ..write('safetyLevel: $safetyLevel, ')
          ..write('smartTunnelPorts: $smartTunnelPorts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    host,
    port,
    username,
    password,
    privateKeyPath,
    passphrase,
    loginScript,
    executeLoginScript,
    groupId,
    tag,
    safetyLevel,
    smartTunnelPorts,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.port == this.port &&
          other.username == this.username &&
          other.password == this.password &&
          other.privateKeyPath == this.privateKeyPath &&
          other.passphrase == this.passphrase &&
          other.loginScript == this.loginScript &&
          other.executeLoginScript == this.executeLoginScript &&
          other.groupId == this.groupId &&
          other.tag == this.tag &&
          other.safetyLevel == this.safetyLevel &&
          other.smartTunnelPorts == this.smartTunnelPorts &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> host;
  final Value<int> port;
  final Value<String> username;
  final Value<String?> password;
  final Value<String?> privateKeyPath;
  final Value<String?> passphrase;
  final Value<String?> loginScript;
  final Value<bool> executeLoginScript;
  final Value<int?> groupId;
  final Value<String?> tag;
  final Value<int> safetyLevel;
  final Value<String?> smartTunnelPorts;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.privateKeyPath = const Value.absent(),
    this.passphrase = const Value.absent(),
    this.loginScript = const Value.absent(),
    this.executeLoginScript = const Value.absent(),
    this.groupId = const Value.absent(),
    this.tag = const Value.absent(),
    this.safetyLevel = const Value.absent(),
    this.smartTunnelPorts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String host,
    this.port = const Value.absent(),
    required String username,
    this.password = const Value.absent(),
    this.privateKeyPath = const Value.absent(),
    this.passphrase = const Value.absent(),
    this.loginScript = const Value.absent(),
    this.executeLoginScript = const Value.absent(),
    this.groupId = const Value.absent(),
    this.tag = const Value.absent(),
    this.safetyLevel = const Value.absent(),
    this.smartTunnelPorts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       host = Value(host),
       username = Value(username);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? privateKeyPath,
    Expression<String>? passphrase,
    Expression<String>? loginScript,
    Expression<bool>? executeLoginScript,
    Expression<int>? groupId,
    Expression<String>? tag,
    Expression<int>? safetyLevel,
    Expression<String>? smartTunnelPorts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (privateKeyPath != null) 'private_key_path': privateKeyPath,
      if (passphrase != null) 'passphrase': passphrase,
      if (loginScript != null) 'login_script': loginScript,
      if (executeLoginScript != null)
        'execute_login_script': executeLoginScript,
      if (groupId != null) 'group_id': groupId,
      if (tag != null) 'tag': tag,
      if (safetyLevel != null) 'safety_level': safetyLevel,
      if (smartTunnelPorts != null) 'smart_tunnel_ports': smartTunnelPorts,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? host,
    Value<int>? port,
    Value<String>? username,
    Value<String?>? password,
    Value<String?>? privateKeyPath,
    Value<String?>? passphrase,
    Value<String?>? loginScript,
    Value<bool>? executeLoginScript,
    Value<int?>? groupId,
    Value<String?>? tag,
    Value<int>? safetyLevel,
    Value<String?>? smartTunnelPorts,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      passphrase: passphrase ?? this.passphrase,
      loginScript: loginScript ?? this.loginScript,
      executeLoginScript: executeLoginScript ?? this.executeLoginScript,
      groupId: groupId ?? this.groupId,
      tag: tag ?? this.tag,
      safetyLevel: safetyLevel ?? this.safetyLevel,
      smartTunnelPorts: smartTunnelPorts ?? this.smartTunnelPorts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (privateKeyPath.present) {
      map['private_key_path'] = Variable<String>(privateKeyPath.value);
    }
    if (passphrase.present) {
      map['passphrase'] = Variable<String>(passphrase.value);
    }
    if (loginScript.present) {
      map['login_script'] = Variable<String>(loginScript.value);
    }
    if (executeLoginScript.present) {
      map['execute_login_script'] = Variable<bool>(executeLoginScript.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<int>(groupId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (safetyLevel.present) {
      map['safety_level'] = Variable<int>(safetyLevel.value);
    }
    if (smartTunnelPorts.present) {
      map['smart_tunnel_ports'] = Variable<String>(smartTunnelPorts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('privateKeyPath: $privateKeyPath, ')
          ..write('passphrase: $passphrase, ')
          ..write('loginScript: $loginScript, ')
          ..write('executeLoginScript: $executeLoginScript, ')
          ..write('groupId: $groupId, ')
          ..write('tag: $tag, ')
          ..write('safetyLevel: $safetyLevel, ')
          ..write('smartTunnelPorts: $smartTunnelPorts, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SessionRecordingsTable extends SessionRecordings
    with TableInfo<$SessionRecordingsTable, SessionRecording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionRecordingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    startTime,
    endTime,
    filePath,
    fileSize,
    name,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRecording> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRecording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRecording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  $SessionRecordingsTable createAlias(String alias) {
    return $SessionRecordingsTable(attachedDatabase, alias);
  }
}

class SessionRecording extends DataClass
    implements Insertable<SessionRecording> {
  final int id;
  final int sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final String filePath;
  final int fileSize;
  final String? name;
  const SessionRecording({
    required this.id,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.filePath,
    required this.fileSize,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  SessionRecordingsCompanion toCompanion(bool nullToAbsent) {
    return SessionRecordingsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory SessionRecording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRecording(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'name': serializer.toJson<String?>(name),
    };
  }

  SessionRecording copyWith({
    int? id,
    int? sessionId,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    String? filePath,
    int? fileSize,
    Value<String?> name = const Value.absent(),
  }) => SessionRecording(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    name: name.present ? name.value : this.name,
  );
  SessionRecording copyWithCompanion(SessionRecordingsCompanion data) {
    return SessionRecording(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecording(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sessionId, startTime, endTime, filePath, fileSize, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRecording &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.name == this.name);
}

class SessionRecordingsCompanion extends UpdateCompanion<SessionRecording> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<String?> name;
  const SessionRecordingsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.name = const Value.absent(),
  });
  SessionRecordingsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    required String filePath,
    this.fileSize = const Value.absent(),
    this.name = const Value.absent(),
  }) : sessionId = Value(sessionId),
       startTime = Value(startTime),
       filePath = Value(filePath);
  static Insertable<SessionRecording> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (name != null) 'name': name,
    });
  }

  SessionRecordingsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<String?>? name,
  }) {
    return SessionRecordingsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      name: name ?? this.name,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionRecordingsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $SessionRecordingsTable sessionRecordings =
      $SessionRecordingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    groups,
    sessions,
    sessionRecordings,
  ];
}

typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> color,
      Value<String?> icon,
      Value<DateTime> createdAt,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> color,
      Value<String?> icon,
      Value<DateTime> createdAt,
    });

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, Group> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SessionsTable, List<Session>> _sessionsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sessions,
    aliasName: $_aliasNameGenerator(db.groups.id, db.sessions.groupId),
  );

  $$SessionsTableProcessedTableManager get sessionsRefs {
    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionsRefs(
    Expression<bool> Function($$SessionsTableFilterComposer f) f,
  ) {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> sessionsRefs<T extends Object>(
    Expression<T> Function($$SessionsTableAnnotationComposer a) f,
  ) {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          Group,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (Group, $$GroupsTableReferences),
          Group,
          PrefetchHooks Function({bool sessionsRefs})
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                color: color,
                icon: icon,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                color: color,
                icon: icon,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GroupsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({sessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionsRefs) db.sessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionsRefs)
                    await $_getPrefetchedData<Group, $GroupsTable, Session>(
                      currentTable: table,
                      referencedTable: $$GroupsTableReferences
                          ._sessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$GroupsTableReferences(db, table, p0).sessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.groupId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      Group,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (Group, $$GroupsTableReferences),
      Group,
      PrefetchHooks Function({bool sessionsRefs})
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String name,
      required String host,
      Value<int> port,
      required String username,
      Value<String?> password,
      Value<String?> privateKeyPath,
      Value<String?> passphrase,
      Value<String?> loginScript,
      Value<bool> executeLoginScript,
      Value<int?> groupId,
      Value<String?> tag,
      Value<int> safetyLevel,
      Value<String?> smartTunnelPorts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> host,
      Value<int> port,
      Value<String> username,
      Value<String?> password,
      Value<String?> privateKeyPath,
      Value<String?> passphrase,
      Value<String?> loginScript,
      Value<bool> executeLoginScript,
      Value<int?> groupId,
      Value<String?> tag,
      Value<int> safetyLevel,
      Value<String?> smartTunnelPorts,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) => db.groups.createAlias(
    $_aliasNameGenerator(db.sessions.groupId, db.groups.id),
  );

  $$GroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<int>('group_id');
    if ($_column == null) return null;
    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SessionRecordingsTable, List<SessionRecording>>
  _sessionRecordingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sessionRecordings,
        aliasName: $_aliasNameGenerator(
          db.sessions.id,
          db.sessionRecordings.sessionId,
        ),
      );

  $$SessionRecordingsTableProcessedTableManager get sessionRecordingsRefs {
    final manager = $$SessionRecordingsTableTableManager(
      $_db,
      $_db.sessionRecordings,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionRecordingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateKeyPath => $composableBuilder(
    column: $table.privateKeyPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passphrase => $composableBuilder(
    column: $table.passphrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loginScript => $composableBuilder(
    column: $table.loginScript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get executeLoginScript => $composableBuilder(
    column: $table.executeLoginScript,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get safetyLevel => $composableBuilder(
    column: $table.safetyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smartTunnelPorts => $composableBuilder(
    column: $table.smartTunnelPorts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionRecordingsRefs(
    Expression<bool> Function($$SessionRecordingsTableFilterComposer f) f,
  ) {
    final $$SessionRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionRecordings,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.sessionRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateKeyPath => $composableBuilder(
    column: $table.privateKeyPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passphrase => $composableBuilder(
    column: $table.passphrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loginScript => $composableBuilder(
    column: $table.loginScript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get executeLoginScript => $composableBuilder(
    column: $table.executeLoginScript,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get safetyLevel => $composableBuilder(
    column: $table.safetyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smartTunnelPorts => $composableBuilder(
    column: $table.smartTunnelPorts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get privateKeyPath => $composableBuilder(
    column: $table.privateKeyPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passphrase => $composableBuilder(
    column: $table.passphrase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loginScript => $composableBuilder(
    column: $table.loginScript,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get executeLoginScript => $composableBuilder(
    column: $table.executeLoginScript,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<int> get safetyLevel => $composableBuilder(
    column: $table.safetyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get smartTunnelPorts => $composableBuilder(
    column: $table.smartTunnelPorts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionRecordingsRefs<T extends Object>(
    Expression<T> Function($$SessionRecordingsTableAnnotationComposer a) f,
  ) {
    final $$SessionRecordingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sessionRecordings,
          getReferencedColumn: (t) => t.sessionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SessionRecordingsTableAnnotationComposer(
                $db: $db,
                $table: $db.sessionRecordings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({bool groupId, bool sessionRecordingsRefs})
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> password = const Value.absent(),
                Value<String?> privateKeyPath = const Value.absent(),
                Value<String?> passphrase = const Value.absent(),
                Value<String?> loginScript = const Value.absent(),
                Value<bool> executeLoginScript = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<int> safetyLevel = const Value.absent(),
                Value<String?> smartTunnelPorts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                name: name,
                host: host,
                port: port,
                username: username,
                password: password,
                privateKeyPath: privateKeyPath,
                passphrase: passphrase,
                loginScript: loginScript,
                executeLoginScript: executeLoginScript,
                groupId: groupId,
                tag: tag,
                safetyLevel: safetyLevel,
                smartTunnelPorts: smartTunnelPorts,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String host,
                Value<int> port = const Value.absent(),
                required String username,
                Value<String?> password = const Value.absent(),
                Value<String?> privateKeyPath = const Value.absent(),
                Value<String?> passphrase = const Value.absent(),
                Value<String?> loginScript = const Value.absent(),
                Value<bool> executeLoginScript = const Value.absent(),
                Value<int?> groupId = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<int> safetyLevel = const Value.absent(),
                Value<String?> smartTunnelPorts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                name: name,
                host: host,
                port: port,
                username: username,
                password: password,
                privateKeyPath: privateKeyPath,
                passphrase: passphrase,
                loginScript: loginScript,
                executeLoginScript: executeLoginScript,
                groupId: groupId,
                tag: tag,
                safetyLevel: safetyLevel,
                smartTunnelPorts: smartTunnelPorts,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, sessionRecordingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionRecordingsRefs) db.sessionRecordings,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable: $$SessionsTableReferences
                                        ._groupIdTable(db),
                                    referencedColumn: $$SessionsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionRecordingsRefs)
                        await $_getPrefetchedData<
                          Session,
                          $SessionsTable,
                          SessionRecording
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._sessionRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionRecordingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({bool groupId, bool sessionRecordingsRefs})
    >;
typedef $$SessionRecordingsTableCreateCompanionBuilder =
    SessionRecordingsCompanion Function({
      Value<int> id,
      required int sessionId,
      required DateTime startTime,
      Value<DateTime?> endTime,
      required String filePath,
      Value<int> fileSize,
      Value<String?> name,
    });
typedef $$SessionRecordingsTableUpdateCompanionBuilder =
    SessionRecordingsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<String> filePath,
      Value<int> fileSize,
      Value<String?> name,
    });

final class $$SessionRecordingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SessionRecordingsTable,
          SessionRecording
        > {
  $$SessionRecordingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias(
        $_aliasNameGenerator(db.sessionRecordings.sessionId, db.sessions.id),
      );

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SessionRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionRecordingsTable> {
  $$SessionRecordingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionRecordingsTable,
          SessionRecording,
          $$SessionRecordingsTableFilterComposer,
          $$SessionRecordingsTableOrderingComposer,
          $$SessionRecordingsTableAnnotationComposer,
          $$SessionRecordingsTableCreateCompanionBuilder,
          $$SessionRecordingsTableUpdateCompanionBuilder,
          (SessionRecording, $$SessionRecordingsTableReferences),
          SessionRecording,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SessionRecordingsTableTableManager(
    _$AppDatabase db,
    $SessionRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionRecordingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => SessionRecordingsCompanion(
                id: id,
                sessionId: sessionId,
                startTime: startTime,
                endTime: endTime,
                filePath: filePath,
                fileSize: fileSize,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                required String filePath,
                Value<int> fileSize = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => SessionRecordingsCompanion.insert(
                id: id,
                sessionId: sessionId,
                startTime: startTime,
                endTime: endTime,
                filePath: filePath,
                fileSize: fileSize,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SessionRecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable:
                                    $$SessionRecordingsTableReferences
                                        ._sessionIdTable(db),
                                referencedColumn:
                                    $$SessionRecordingsTableReferences
                                        ._sessionIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionRecordingsTable,
      SessionRecording,
      $$SessionRecordingsTableFilterComposer,
      $$SessionRecordingsTableOrderingComposer,
      $$SessionRecordingsTableAnnotationComposer,
      $$SessionRecordingsTableCreateCompanionBuilder,
      $$SessionRecordingsTableUpdateCompanionBuilder,
      (SessionRecording, $$SessionRecordingsTableReferences),
      SessionRecording,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$SessionRecordingsTableTableManager get sessionRecordings =>
      $$SessionRecordingsTableTableManager(_db, _db.sessionRecordings);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(database)
const databaseProvider = DatabaseProvider._();

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  const DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'e5a1fa0e8ff9aa131f847f28519ec2098e6d0f76';
