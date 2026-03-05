// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IglesiasTable extends Iglesias with TableInfo<$IglesiasTable, Iglesia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IglesiasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distritoMeta = const VerificationMeta(
    'distrito',
  );
  @override
  late final GeneratedColumn<int> distrito = GeneratedColumn<int>(
    'distrito',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaLlegadaMeta = const VerificationMeta(
    'fechaLlegada',
  );
  @override
  late final GeneratedColumn<DateTime> fechaLlegada = GeneratedColumn<DateTime>(
    'fecha_llegada',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaSalidaMeta = const VerificationMeta(
    'fechaSalida',
  );
  @override
  late final GeneratedColumn<DateTime> fechaSalida = GeneratedColumn<DateTime>(
    'fecha_salida',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    nombre,
    distrito,
    fechaLlegada,
    fechaSalida,
    categoria,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'iglesias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Iglesia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('distrito')) {
      context.handle(
        _distritoMeta,
        distrito.isAcceptableOrUnknown(data['distrito']!, _distritoMeta),
      );
    } else if (isInserting) {
      context.missing(_distritoMeta);
    }
    if (data.containsKey('fecha_llegada')) {
      context.handle(
        _fechaLlegadaMeta,
        fechaLlegada.isAcceptableOrUnknown(
          data['fecha_llegada']!,
          _fechaLlegadaMeta,
        ),
      );
    }
    if (data.containsKey('fecha_salida')) {
      context.handle(
        _fechaSalidaMeta,
        fechaSalida.isAcceptableOrUnknown(
          data['fecha_salida']!,
          _fechaSalidaMeta,
        ),
      );
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Iglesia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Iglesia(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      distrito: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distrito'],
      )!,
      fechaLlegada: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_llegada'],
      ),
      fechaSalida: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_salida'],
      ),
      categoria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $IglesiasTable createAlias(String alias) {
    return $IglesiasTable(attachedDatabase, alias);
  }
}

class Iglesia extends DataClass implements Insertable<Iglesia> {
  final String id;
  final String userId;
  final String nombre;
  final int distrito;
  final DateTime? fechaLlegada;
  final DateTime? fechaSalida;
  final String? categoria;
  final int syncStatus;
  const Iglesia({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.distrito,
    this.fechaLlegada,
    this.fechaSalida,
    this.categoria,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['nombre'] = Variable<String>(nombre);
    map['distrito'] = Variable<int>(distrito);
    if (!nullToAbsent || fechaLlegada != null) {
      map['fecha_llegada'] = Variable<DateTime>(fechaLlegada);
    }
    if (!nullToAbsent || fechaSalida != null) {
      map['fecha_salida'] = Variable<DateTime>(fechaSalida);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  IglesiasCompanion toCompanion(bool nullToAbsent) {
    return IglesiasCompanion(
      id: Value(id),
      userId: Value(userId),
      nombre: Value(nombre),
      distrito: Value(distrito),
      fechaLlegada: fechaLlegada == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaLlegada),
      fechaSalida: fechaSalida == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaSalida),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      syncStatus: Value(syncStatus),
    );
  }

  factory Iglesia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Iglesia(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      distrito: serializer.fromJson<int>(json['distrito']),
      fechaLlegada: serializer.fromJson<DateTime?>(json['fechaLlegada']),
      fechaSalida: serializer.fromJson<DateTime?>(json['fechaSalida']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'nombre': serializer.toJson<String>(nombre),
      'distrito': serializer.toJson<int>(distrito),
      'fechaLlegada': serializer.toJson<DateTime?>(fechaLlegada),
      'fechaSalida': serializer.toJson<DateTime?>(fechaSalida),
      'categoria': serializer.toJson<String?>(categoria),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Iglesia copyWith({
    String? id,
    String? userId,
    String? nombre,
    int? distrito,
    Value<DateTime?> fechaLlegada = const Value.absent(),
    Value<DateTime?> fechaSalida = const Value.absent(),
    Value<String?> categoria = const Value.absent(),
    int? syncStatus,
  }) => Iglesia(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    nombre: nombre ?? this.nombre,
    distrito: distrito ?? this.distrito,
    fechaLlegada: fechaLlegada.present ? fechaLlegada.value : this.fechaLlegada,
    fechaSalida: fechaSalida.present ? fechaSalida.value : this.fechaSalida,
    categoria: categoria.present ? categoria.value : this.categoria,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Iglesia copyWithCompanion(IglesiasCompanion data) {
    return Iglesia(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      distrito: data.distrito.present ? data.distrito.value : this.distrito,
      fechaLlegada: data.fechaLlegada.present
          ? data.fechaLlegada.value
          : this.fechaLlegada,
      fechaSalida: data.fechaSalida.present
          ? data.fechaSalida.value
          : this.fechaSalida,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Iglesia(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nombre: $nombre, ')
          ..write('distrito: $distrito, ')
          ..write('fechaLlegada: $fechaLlegada, ')
          ..write('fechaSalida: $fechaSalida, ')
          ..write('categoria: $categoria, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    nombre,
    distrito,
    fechaLlegada,
    fechaSalida,
    categoria,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Iglesia &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.nombre == this.nombre &&
          other.distrito == this.distrito &&
          other.fechaLlegada == this.fechaLlegada &&
          other.fechaSalida == this.fechaSalida &&
          other.categoria == this.categoria &&
          other.syncStatus == this.syncStatus);
}

class IglesiasCompanion extends UpdateCompanion<Iglesia> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> nombre;
  final Value<int> distrito;
  final Value<DateTime?> fechaLlegada;
  final Value<DateTime?> fechaSalida;
  final Value<String?> categoria;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const IglesiasCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.distrito = const Value.absent(),
    this.fechaLlegada = const Value.absent(),
    this.fechaSalida = const Value.absent(),
    this.categoria = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IglesiasCompanion.insert({
    required String id,
    required String userId,
    required String nombre,
    required int distrito,
    this.fechaLlegada = const Value.absent(),
    this.fechaSalida = const Value.absent(),
    this.categoria = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       nombre = Value(nombre),
       distrito = Value(distrito);
  static Insertable<Iglesia> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? nombre,
    Expression<int>? distrito,
    Expression<DateTime>? fechaLlegada,
    Expression<DateTime>? fechaSalida,
    Expression<String>? categoria,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (nombre != null) 'nombre': nombre,
      if (distrito != null) 'distrito': distrito,
      if (fechaLlegada != null) 'fecha_llegada': fechaLlegada,
      if (fechaSalida != null) 'fecha_salida': fechaSalida,
      if (categoria != null) 'categoria': categoria,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IglesiasCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? nombre,
    Value<int>? distrito,
    Value<DateTime?>? fechaLlegada,
    Value<DateTime?>? fechaSalida,
    Value<String?>? categoria,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return IglesiasCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      distrito: distrito ?? this.distrito,
      fechaLlegada: fechaLlegada ?? this.fechaLlegada,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      categoria: categoria ?? this.categoria,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (distrito.present) {
      map['distrito'] = Variable<int>(distrito.value);
    }
    if (fechaLlegada.present) {
      map['fecha_llegada'] = Variable<DateTime>(fechaLlegada.value);
    }
    if (fechaSalida.present) {
      map['fecha_salida'] = Variable<DateTime>(fechaSalida.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IglesiasCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('nombre: $nombre, ')
          ..write('distrito: $distrito, ')
          ..write('fechaLlegada: $fechaLlegada, ')
          ..write('fechaSalida: $fechaSalida, ')
          ..write('categoria: $categoria, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeligresesTable extends Feligreses
    with TableInfo<$FeligresesTable, Feligrese> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeligresesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaNacimientoMeta = const VerificationMeta(
    'fechaNacimiento',
  );
  @override
  late final GeneratedColumn<DateTime> fechaNacimiento =
      GeneratedColumn<DateTime>(
        'fecha_nacimiento',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _generoMeta = const VerificationMeta('genero');
  @override
  late final GeneratedColumn<String> genero = GeneratedColumn<String>(
    'genero',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<int> activo = GeneratedColumn<int>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _cedulaMeta = const VerificationMeta('cedula');
  @override
  late final GeneratedColumn<String> cedula = GeneratedColumn<String>(
    'cedula',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoCivilMeta = const VerificationMeta(
    'estadoCivil',
  );
  @override
  late final GeneratedColumn<String> estadoCivil = GeneratedColumn<String>(
    'estado_civil',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _poseeDiscapacidadMeta = const VerificationMeta(
    'poseeDiscapacidad',
  );
  @override
  late final GeneratedColumn<bool> poseeDiscapacidad = GeneratedColumn<bool>(
    'posee_discapacidad',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("posee_discapacidad" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bautizadoAguaMeta = const VerificationMeta(
    'bautizadoAgua',
  );
  @override
  late final GeneratedColumn<bool> bautizadoAgua = GeneratedColumn<bool>(
    'bautizado_agua',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bautizado_agua" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bautizadoEspirituMeta = const VerificationMeta(
    'bautizadoEspiritu',
  );
  @override
  late final GeneratedColumn<bool> bautizadoEspiritu = GeneratedColumn<bool>(
    'bautizado_espiritu',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bautizado_espiritu" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tipoFeligresMeta = const VerificationMeta(
    'tipoFeligres',
  );
  @override
  late final GeneratedColumn<String> tipoFeligres = GeneratedColumn<String>(
    'tipo_feligres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('feligres'),
  );
  static const VerificationMeta _iglesiaIdMeta = const VerificationMeta(
    'iglesiaId',
  );
  @override
  late final GeneratedColumn<String> iglesiaId = GeneratedColumn<String>(
    'iglesia_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES iglesias (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    fechaNacimiento,
    genero,
    telefono,
    activo,
    syncStatus,
    cedula,
    estadoCivil,
    poseeDiscapacidad,
    bautizadoAgua,
    bautizadoEspiritu,
    tipoFeligres,
    iglesiaId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feligreses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Feligrese> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('fecha_nacimiento')) {
      context.handle(
        _fechaNacimientoMeta,
        fechaNacimiento.isAcceptableOrUnknown(
          data['fecha_nacimiento']!,
          _fechaNacimientoMeta,
        ),
      );
    }
    if (data.containsKey('genero')) {
      context.handle(
        _generoMeta,
        genero.isAcceptableOrUnknown(data['genero']!, _generoMeta),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('cedula')) {
      context.handle(
        _cedulaMeta,
        cedula.isAcceptableOrUnknown(data['cedula']!, _cedulaMeta),
      );
    }
    if (data.containsKey('estado_civil')) {
      context.handle(
        _estadoCivilMeta,
        estadoCivil.isAcceptableOrUnknown(
          data['estado_civil']!,
          _estadoCivilMeta,
        ),
      );
    }
    if (data.containsKey('posee_discapacidad')) {
      context.handle(
        _poseeDiscapacidadMeta,
        poseeDiscapacidad.isAcceptableOrUnknown(
          data['posee_discapacidad']!,
          _poseeDiscapacidadMeta,
        ),
      );
    }
    if (data.containsKey('bautizado_agua')) {
      context.handle(
        _bautizadoAguaMeta,
        bautizadoAgua.isAcceptableOrUnknown(
          data['bautizado_agua']!,
          _bautizadoAguaMeta,
        ),
      );
    }
    if (data.containsKey('bautizado_espiritu')) {
      context.handle(
        _bautizadoEspirituMeta,
        bautizadoEspiritu.isAcceptableOrUnknown(
          data['bautizado_espiritu']!,
          _bautizadoEspirituMeta,
        ),
      );
    }
    if (data.containsKey('tipo_feligres')) {
      context.handle(
        _tipoFeligresMeta,
        tipoFeligres.isAcceptableOrUnknown(
          data['tipo_feligres']!,
          _tipoFeligresMeta,
        ),
      );
    }
    if (data.containsKey('iglesia_id')) {
      context.handle(
        _iglesiaIdMeta,
        iglesiaId.isAcceptableOrUnknown(data['iglesia_id']!, _iglesiaIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Feligrese map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Feligrese(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      fechaNacimiento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha_nacimiento'],
      ),
      genero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genero'],
      ),
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}activo'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
      cedula: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cedula'],
      ),
      estadoCivil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado_civil'],
      ),
      poseeDiscapacidad: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}posee_discapacidad'],
      )!,
      bautizadoAgua: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bautizado_agua'],
      )!,
      bautizadoEspiritu: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bautizado_espiritu'],
      )!,
      tipoFeligres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo_feligres'],
      )!,
      iglesiaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iglesia_id'],
      ),
    );
  }

  @override
  $FeligresesTable createAlias(String alias) {
    return $FeligresesTable(attachedDatabase, alias);
  }
}

class Feligrese extends DataClass implements Insertable<Feligrese> {
  final String id;
  final String nombre;
  final DateTime? fechaNacimiento;
  final String? genero;
  final String? telefono;
  final int activo;
  final int syncStatus;
  final String? cedula;
  final String? estadoCivil;
  final bool poseeDiscapacidad;
  final bool bautizadoAgua;
  final bool bautizadoEspiritu;
  final String tipoFeligres;
  final String? iglesiaId;
  const Feligrese({
    required this.id,
    required this.nombre,
    this.fechaNacimiento,
    this.genero,
    this.telefono,
    required this.activo,
    required this.syncStatus,
    this.cedula,
    this.estadoCivil,
    required this.poseeDiscapacidad,
    required this.bautizadoAgua,
    required this.bautizadoEspiritu,
    required this.tipoFeligres,
    this.iglesiaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || fechaNacimiento != null) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento);
    }
    if (!nullToAbsent || genero != null) {
      map['genero'] = Variable<String>(genero);
    }
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    map['activo'] = Variable<int>(activo);
    map['sync_status'] = Variable<int>(syncStatus);
    if (!nullToAbsent || cedula != null) {
      map['cedula'] = Variable<String>(cedula);
    }
    if (!nullToAbsent || estadoCivil != null) {
      map['estado_civil'] = Variable<String>(estadoCivil);
    }
    map['posee_discapacidad'] = Variable<bool>(poseeDiscapacidad);
    map['bautizado_agua'] = Variable<bool>(bautizadoAgua);
    map['bautizado_espiritu'] = Variable<bool>(bautizadoEspiritu);
    map['tipo_feligres'] = Variable<String>(tipoFeligres);
    if (!nullToAbsent || iglesiaId != null) {
      map['iglesia_id'] = Variable<String>(iglesiaId);
    }
    return map;
  }

  FeligresesCompanion toCompanion(bool nullToAbsent) {
    return FeligresesCompanion(
      id: Value(id),
      nombre: Value(nombre),
      fechaNacimiento: fechaNacimiento == null && nullToAbsent
          ? const Value.absent()
          : Value(fechaNacimiento),
      genero: genero == null && nullToAbsent
          ? const Value.absent()
          : Value(genero),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      activo: Value(activo),
      syncStatus: Value(syncStatus),
      cedula: cedula == null && nullToAbsent
          ? const Value.absent()
          : Value(cedula),
      estadoCivil: estadoCivil == null && nullToAbsent
          ? const Value.absent()
          : Value(estadoCivil),
      poseeDiscapacidad: Value(poseeDiscapacidad),
      bautizadoAgua: Value(bautizadoAgua),
      bautizadoEspiritu: Value(bautizadoEspiritu),
      tipoFeligres: Value(tipoFeligres),
      iglesiaId: iglesiaId == null && nullToAbsent
          ? const Value.absent()
          : Value(iglesiaId),
    );
  }

  factory Feligrese.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Feligrese(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fechaNacimiento: serializer.fromJson<DateTime?>(json['fechaNacimiento']),
      genero: serializer.fromJson<String?>(json['genero']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      activo: serializer.fromJson<int>(json['activo']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      cedula: serializer.fromJson<String?>(json['cedula']),
      estadoCivil: serializer.fromJson<String?>(json['estadoCivil']),
      poseeDiscapacidad: serializer.fromJson<bool>(json['poseeDiscapacidad']),
      bautizadoAgua: serializer.fromJson<bool>(json['bautizadoAgua']),
      bautizadoEspiritu: serializer.fromJson<bool>(json['bautizadoEspiritu']),
      tipoFeligres: serializer.fromJson<String>(json['tipoFeligres']),
      iglesiaId: serializer.fromJson<String?>(json['iglesiaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'fechaNacimiento': serializer.toJson<DateTime?>(fechaNacimiento),
      'genero': serializer.toJson<String?>(genero),
      'telefono': serializer.toJson<String?>(telefono),
      'activo': serializer.toJson<int>(activo),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'cedula': serializer.toJson<String?>(cedula),
      'estadoCivil': serializer.toJson<String?>(estadoCivil),
      'poseeDiscapacidad': serializer.toJson<bool>(poseeDiscapacidad),
      'bautizadoAgua': serializer.toJson<bool>(bautizadoAgua),
      'bautizadoEspiritu': serializer.toJson<bool>(bautizadoEspiritu),
      'tipoFeligres': serializer.toJson<String>(tipoFeligres),
      'iglesiaId': serializer.toJson<String?>(iglesiaId),
    };
  }

  Feligrese copyWith({
    String? id,
    String? nombre,
    Value<DateTime?> fechaNacimiento = const Value.absent(),
    Value<String?> genero = const Value.absent(),
    Value<String?> telefono = const Value.absent(),
    int? activo,
    int? syncStatus,
    Value<String?> cedula = const Value.absent(),
    Value<String?> estadoCivil = const Value.absent(),
    bool? poseeDiscapacidad,
    bool? bautizadoAgua,
    bool? bautizadoEspiritu,
    String? tipoFeligres,
    Value<String?> iglesiaId = const Value.absent(),
  }) => Feligrese(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    fechaNacimiento: fechaNacimiento.present
        ? fechaNacimiento.value
        : this.fechaNacimiento,
    genero: genero.present ? genero.value : this.genero,
    telefono: telefono.present ? telefono.value : this.telefono,
    activo: activo ?? this.activo,
    syncStatus: syncStatus ?? this.syncStatus,
    cedula: cedula.present ? cedula.value : this.cedula,
    estadoCivil: estadoCivil.present ? estadoCivil.value : this.estadoCivil,
    poseeDiscapacidad: poseeDiscapacidad ?? this.poseeDiscapacidad,
    bautizadoAgua: bautizadoAgua ?? this.bautizadoAgua,
    bautizadoEspiritu: bautizadoEspiritu ?? this.bautizadoEspiritu,
    tipoFeligres: tipoFeligres ?? this.tipoFeligres,
    iglesiaId: iglesiaId.present ? iglesiaId.value : this.iglesiaId,
  );
  Feligrese copyWithCompanion(FeligresesCompanion data) {
    return Feligrese(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fechaNacimiento: data.fechaNacimiento.present
          ? data.fechaNacimiento.value
          : this.fechaNacimiento,
      genero: data.genero.present ? data.genero.value : this.genero,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      activo: data.activo.present ? data.activo.value : this.activo,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      cedula: data.cedula.present ? data.cedula.value : this.cedula,
      estadoCivil: data.estadoCivil.present
          ? data.estadoCivil.value
          : this.estadoCivil,
      poseeDiscapacidad: data.poseeDiscapacidad.present
          ? data.poseeDiscapacidad.value
          : this.poseeDiscapacidad,
      bautizadoAgua: data.bautizadoAgua.present
          ? data.bautizadoAgua.value
          : this.bautizadoAgua,
      bautizadoEspiritu: data.bautizadoEspiritu.present
          ? data.bautizadoEspiritu.value
          : this.bautizadoEspiritu,
      tipoFeligres: data.tipoFeligres.present
          ? data.tipoFeligres.value
          : this.tipoFeligres,
      iglesiaId: data.iglesiaId.present ? data.iglesiaId.value : this.iglesiaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Feligrese(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('genero: $genero, ')
          ..write('telefono: $telefono, ')
          ..write('activo: $activo, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cedula: $cedula, ')
          ..write('estadoCivil: $estadoCivil, ')
          ..write('poseeDiscapacidad: $poseeDiscapacidad, ')
          ..write('bautizadoAgua: $bautizadoAgua, ')
          ..write('bautizadoEspiritu: $bautizadoEspiritu, ')
          ..write('tipoFeligres: $tipoFeligres, ')
          ..write('iglesiaId: $iglesiaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    fechaNacimiento,
    genero,
    telefono,
    activo,
    syncStatus,
    cedula,
    estadoCivil,
    poseeDiscapacidad,
    bautizadoAgua,
    bautizadoEspiritu,
    tipoFeligres,
    iglesiaId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Feligrese &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.fechaNacimiento == this.fechaNacimiento &&
          other.genero == this.genero &&
          other.telefono == this.telefono &&
          other.activo == this.activo &&
          other.syncStatus == this.syncStatus &&
          other.cedula == this.cedula &&
          other.estadoCivil == this.estadoCivil &&
          other.poseeDiscapacidad == this.poseeDiscapacidad &&
          other.bautizadoAgua == this.bautizadoAgua &&
          other.bautizadoEspiritu == this.bautizadoEspiritu &&
          other.tipoFeligres == this.tipoFeligres &&
          other.iglesiaId == this.iglesiaId);
}

class FeligresesCompanion extends UpdateCompanion<Feligrese> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<DateTime?> fechaNacimiento;
  final Value<String?> genero;
  final Value<String?> telefono;
  final Value<int> activo;
  final Value<int> syncStatus;
  final Value<String?> cedula;
  final Value<String?> estadoCivil;
  final Value<bool> poseeDiscapacidad;
  final Value<bool> bautizadoAgua;
  final Value<bool> bautizadoEspiritu;
  final Value<String> tipoFeligres;
  final Value<String?> iglesiaId;
  final Value<int> rowid;
  const FeligresesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.genero = const Value.absent(),
    this.telefono = const Value.absent(),
    this.activo = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.cedula = const Value.absent(),
    this.estadoCivil = const Value.absent(),
    this.poseeDiscapacidad = const Value.absent(),
    this.bautizadoAgua = const Value.absent(),
    this.bautizadoEspiritu = const Value.absent(),
    this.tipoFeligres = const Value.absent(),
    this.iglesiaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeligresesCompanion.insert({
    required String id,
    required String nombre,
    this.fechaNacimiento = const Value.absent(),
    this.genero = const Value.absent(),
    this.telefono = const Value.absent(),
    this.activo = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.cedula = const Value.absent(),
    this.estadoCivil = const Value.absent(),
    this.poseeDiscapacidad = const Value.absent(),
    this.bautizadoAgua = const Value.absent(),
    this.bautizadoEspiritu = const Value.absent(),
    this.tipoFeligres = const Value.absent(),
    this.iglesiaId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre);
  static Insertable<Feligrese> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<DateTime>? fechaNacimiento,
    Expression<String>? genero,
    Expression<String>? telefono,
    Expression<int>? activo,
    Expression<int>? syncStatus,
    Expression<String>? cedula,
    Expression<String>? estadoCivil,
    Expression<bool>? poseeDiscapacidad,
    Expression<bool>? bautizadoAgua,
    Expression<bool>? bautizadoEspiritu,
    Expression<String>? tipoFeligres,
    Expression<String>? iglesiaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
      if (genero != null) 'genero': genero,
      if (telefono != null) 'telefono': telefono,
      if (activo != null) 'activo': activo,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (cedula != null) 'cedula': cedula,
      if (estadoCivil != null) 'estado_civil': estadoCivil,
      if (poseeDiscapacidad != null) 'posee_discapacidad': poseeDiscapacidad,
      if (bautizadoAgua != null) 'bautizado_agua': bautizadoAgua,
      if (bautizadoEspiritu != null) 'bautizado_espiritu': bautizadoEspiritu,
      if (tipoFeligres != null) 'tipo_feligres': tipoFeligres,
      if (iglesiaId != null) 'iglesia_id': iglesiaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeligresesCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<DateTime?>? fechaNacimiento,
    Value<String?>? genero,
    Value<String?>? telefono,
    Value<int>? activo,
    Value<int>? syncStatus,
    Value<String?>? cedula,
    Value<String?>? estadoCivil,
    Value<bool>? poseeDiscapacidad,
    Value<bool>? bautizadoAgua,
    Value<bool>? bautizadoEspiritu,
    Value<String>? tipoFeligres,
    Value<String?>? iglesiaId,
    Value<int>? rowid,
  }) {
    return FeligresesCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      genero: genero ?? this.genero,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      syncStatus: syncStatus ?? this.syncStatus,
      cedula: cedula ?? this.cedula,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      poseeDiscapacidad: poseeDiscapacidad ?? this.poseeDiscapacidad,
      bautizadoAgua: bautizadoAgua ?? this.bautizadoAgua,
      bautizadoEspiritu: bautizadoEspiritu ?? this.bautizadoEspiritu,
      tipoFeligres: tipoFeligres ?? this.tipoFeligres,
      iglesiaId: iglesiaId ?? this.iglesiaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (fechaNacimiento.present) {
      map['fecha_nacimiento'] = Variable<DateTime>(fechaNacimiento.value);
    }
    if (genero.present) {
      map['genero'] = Variable<String>(genero.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (activo.present) {
      map['activo'] = Variable<int>(activo.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (cedula.present) {
      map['cedula'] = Variable<String>(cedula.value);
    }
    if (estadoCivil.present) {
      map['estado_civil'] = Variable<String>(estadoCivil.value);
    }
    if (poseeDiscapacidad.present) {
      map['posee_discapacidad'] = Variable<bool>(poseeDiscapacidad.value);
    }
    if (bautizadoAgua.present) {
      map['bautizado_agua'] = Variable<bool>(bautizadoAgua.value);
    }
    if (bautizadoEspiritu.present) {
      map['bautizado_espiritu'] = Variable<bool>(bautizadoEspiritu.value);
    }
    if (tipoFeligres.present) {
      map['tipo_feligres'] = Variable<String>(tipoFeligres.value);
    }
    if (iglesiaId.present) {
      map['iglesia_id'] = Variable<String>(iglesiaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeligresesCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaNacimiento: $fechaNacimiento, ')
          ..write('genero: $genero, ')
          ..write('telefono: $telefono, ')
          ..write('activo: $activo, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('cedula: $cedula, ')
          ..write('estadoCivil: $estadoCivil, ')
          ..write('poseeDiscapacidad: $poseeDiscapacidad, ')
          ..write('bautizadoAgua: $bautizadoAgua, ')
          ..write('bautizadoEspiritu: $bautizadoEspiritu, ')
          ..write('tipoFeligres: $tipoFeligres, ')
          ..write('iglesiaId: $iglesiaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AportesTable extends Aportes with TableInfo<$AportesTable, Aporte> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AportesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feligresIdMeta = const VerificationMeta(
    'feligresId',
  );
  @override
  late final GeneratedColumn<String> feligresId = GeneratedColumn<String>(
    'feligres_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES feligreses (id)',
    ),
  );
  static const VerificationMeta _montoMeta = const VerificationMeta('monto');
  @override
  late final GeneratedColumn<double> monto = GeneratedColumn<double>(
    'monto',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    feligresId,
    monto,
    tipo,
    fecha,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aportes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Aporte> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('feligres_id')) {
      context.handle(
        _feligresIdMeta,
        feligresId.isAcceptableOrUnknown(data['feligres_id']!, _feligresIdMeta),
      );
    } else if (isInserting) {
      context.missing(_feligresIdMeta);
    }
    if (data.containsKey('monto')) {
      context.handle(
        _montoMeta,
        monto.isAcceptableOrUnknown(data['monto']!, _montoMeta),
      );
    } else if (isInserting) {
      context.missing(_montoMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Aporte map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Aporte(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      feligresId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feligres_id'],
      )!,
      monto: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}monto'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $AportesTable createAlias(String alias) {
    return $AportesTable(attachedDatabase, alias);
  }
}

class Aporte extends DataClass implements Insertable<Aporte> {
  final String id;
  final String feligresId;
  final double monto;
  final String tipo;
  final DateTime fecha;
  final int syncStatus;
  const Aporte({
    required this.id,
    required this.feligresId,
    required this.monto,
    required this.tipo,
    required this.fecha,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['feligres_id'] = Variable<String>(feligresId);
    map['monto'] = Variable<double>(monto);
    map['tipo'] = Variable<String>(tipo);
    map['fecha'] = Variable<DateTime>(fecha);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  AportesCompanion toCompanion(bool nullToAbsent) {
    return AportesCompanion(
      id: Value(id),
      feligresId: Value(feligresId),
      monto: Value(monto),
      tipo: Value(tipo),
      fecha: Value(fecha),
      syncStatus: Value(syncStatus),
    );
  }

  factory Aporte.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aporte(
      id: serializer.fromJson<String>(json['id']),
      feligresId: serializer.fromJson<String>(json['feligresId']),
      monto: serializer.fromJson<double>(json['monto']),
      tipo: serializer.fromJson<String>(json['tipo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'feligresId': serializer.toJson<String>(feligresId),
      'monto': serializer.toJson<double>(monto),
      'tipo': serializer.toJson<String>(tipo),
      'fecha': serializer.toJson<DateTime>(fecha),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  Aporte copyWith({
    String? id,
    String? feligresId,
    double? monto,
    String? tipo,
    DateTime? fecha,
    int? syncStatus,
  }) => Aporte(
    id: id ?? this.id,
    feligresId: feligresId ?? this.feligresId,
    monto: monto ?? this.monto,
    tipo: tipo ?? this.tipo,
    fecha: fecha ?? this.fecha,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  Aporte copyWithCompanion(AportesCompanion data) {
    return Aporte(
      id: data.id.present ? data.id.value : this.id,
      feligresId: data.feligresId.present
          ? data.feligresId.value
          : this.feligresId,
      monto: data.monto.present ? data.monto.value : this.monto,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aporte(')
          ..write('id: $id, ')
          ..write('feligresId: $feligresId, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, feligresId, monto, tipo, fecha, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aporte &&
          other.id == this.id &&
          other.feligresId == this.feligresId &&
          other.monto == this.monto &&
          other.tipo == this.tipo &&
          other.fecha == this.fecha &&
          other.syncStatus == this.syncStatus);
}

class AportesCompanion extends UpdateCompanion<Aporte> {
  final Value<String> id;
  final Value<String> feligresId;
  final Value<double> monto;
  final Value<String> tipo;
  final Value<DateTime> fecha;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const AportesCompanion({
    this.id = const Value.absent(),
    this.feligresId = const Value.absent(),
    this.monto = const Value.absent(),
    this.tipo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AportesCompanion.insert({
    required String id,
    required String feligresId,
    required double monto,
    required String tipo,
    this.fecha = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       feligresId = Value(feligresId),
       monto = Value(monto),
       tipo = Value(tipo);
  static Insertable<Aporte> custom({
    Expression<String>? id,
    Expression<String>? feligresId,
    Expression<double>? monto,
    Expression<String>? tipo,
    Expression<DateTime>? fecha,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (feligresId != null) 'feligres_id': feligresId,
      if (monto != null) 'monto': monto,
      if (tipo != null) 'tipo': tipo,
      if (fecha != null) 'fecha': fecha,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AportesCompanion copyWith({
    Value<String>? id,
    Value<String>? feligresId,
    Value<double>? monto,
    Value<String>? tipo,
    Value<DateTime>? fecha,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return AportesCompanion(
      id: id ?? this.id,
      feligresId: feligresId ?? this.feligresId,
      monto: monto ?? this.monto,
      tipo: tipo ?? this.tipo,
      fecha: fecha ?? this.fecha,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (feligresId.present) {
      map['feligres_id'] = Variable<String>(feligresId.value);
    }
    if (monto.present) {
      map['monto'] = Variable<double>(monto.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AportesCompanion(')
          ..write('id: $id, ')
          ..write('feligresId: $feligresId, ')
          ..write('monto: $monto, ')
          ..write('tipo: $tipo, ')
          ..write('fecha: $fecha, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IglesiasTable iglesias = $IglesiasTable(this);
  late final $FeligresesTable feligreses = $FeligresesTable(this);
  late final $AportesTable aportes = $AportesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    iglesias,
    feligreses,
    aportes,
  ];
}

typedef $$IglesiasTableCreateCompanionBuilder =
    IglesiasCompanion Function({
      required String id,
      required String userId,
      required String nombre,
      required int distrito,
      Value<DateTime?> fechaLlegada,
      Value<DateTime?> fechaSalida,
      Value<String?> categoria,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$IglesiasTableUpdateCompanionBuilder =
    IglesiasCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> nombre,
      Value<int> distrito,
      Value<DateTime?> fechaLlegada,
      Value<DateTime?> fechaSalida,
      Value<String?> categoria,
      Value<int> syncStatus,
      Value<int> rowid,
    });

final class $$IglesiasTableReferences
    extends BaseReferences<_$AppDatabase, $IglesiasTable, Iglesia> {
  $$IglesiasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$FeligresesTable, List<Feligrese>>
  _feligresesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feligreses,
    aliasName: $_aliasNameGenerator(db.iglesias.id, db.feligreses.iglesiaId),
  );

  $$FeligresesTableProcessedTableManager get feligresesRefs {
    final manager = $$FeligresesTableTableManager(
      $_db,
      $_db.feligreses,
    ).filter((f) => f.iglesiaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_feligresesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IglesiasTableFilterComposer
    extends Composer<_$AppDatabase, $IglesiasTable> {
  $$IglesiasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distrito => $composableBuilder(
    column: $table.distrito,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaLlegada => $composableBuilder(
    column: $table.fechaLlegada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaSalida => $composableBuilder(
    column: $table.fechaSalida,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> feligresesRefs(
    Expression<bool> Function($$FeligresesTableFilterComposer f) f,
  ) {
    final $$FeligresesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feligreses,
      getReferencedColumn: (t) => t.iglesiaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeligresesTableFilterComposer(
            $db: $db,
            $table: $db.feligreses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IglesiasTableOrderingComposer
    extends Composer<_$AppDatabase, $IglesiasTable> {
  $$IglesiasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distrito => $composableBuilder(
    column: $table.distrito,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaLlegada => $composableBuilder(
    column: $table.fechaLlegada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaSalida => $composableBuilder(
    column: $table.fechaSalida,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IglesiasTableAnnotationComposer
    extends Composer<_$AppDatabase, $IglesiasTable> {
  $$IglesiasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get distrito =>
      $composableBuilder(column: $table.distrito, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaLlegada => $composableBuilder(
    column: $table.fechaLlegada,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fechaSalida => $composableBuilder(
    column: $table.fechaSalida,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> feligresesRefs<T extends Object>(
    Expression<T> Function($$FeligresesTableAnnotationComposer a) f,
  ) {
    final $$FeligresesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.feligreses,
      getReferencedColumn: (t) => t.iglesiaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeligresesTableAnnotationComposer(
            $db: $db,
            $table: $db.feligreses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IglesiasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IglesiasTable,
          Iglesia,
          $$IglesiasTableFilterComposer,
          $$IglesiasTableOrderingComposer,
          $$IglesiasTableAnnotationComposer,
          $$IglesiasTableCreateCompanionBuilder,
          $$IglesiasTableUpdateCompanionBuilder,
          (Iglesia, $$IglesiasTableReferences),
          Iglesia,
          PrefetchHooks Function({bool feligresesRefs})
        > {
  $$IglesiasTableTableManager(_$AppDatabase db, $IglesiasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IglesiasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IglesiasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IglesiasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> distrito = const Value.absent(),
                Value<DateTime?> fechaLlegada = const Value.absent(),
                Value<DateTime?> fechaSalida = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IglesiasCompanion(
                id: id,
                userId: userId,
                nombre: nombre,
                distrito: distrito,
                fechaLlegada: fechaLlegada,
                fechaSalida: fechaSalida,
                categoria: categoria,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String nombre,
                required int distrito,
                Value<DateTime?> fechaLlegada = const Value.absent(),
                Value<DateTime?> fechaSalida = const Value.absent(),
                Value<String?> categoria = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IglesiasCompanion.insert(
                id: id,
                userId: userId,
                nombre: nombre,
                distrito: distrito,
                fechaLlegada: fechaLlegada,
                fechaSalida: fechaSalida,
                categoria: categoria,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IglesiasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({feligresesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (feligresesRefs) db.feligreses],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (feligresesRefs)
                    await $_getPrefetchedData<
                      Iglesia,
                      $IglesiasTable,
                      Feligrese
                    >(
                      currentTable: table,
                      referencedTable: $$IglesiasTableReferences
                          ._feligresesRefsTable(db),
                      managerFromTypedResult: (p0) => $$IglesiasTableReferences(
                        db,
                        table,
                        p0,
                      ).feligresesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.iglesiaId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$IglesiasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IglesiasTable,
      Iglesia,
      $$IglesiasTableFilterComposer,
      $$IglesiasTableOrderingComposer,
      $$IglesiasTableAnnotationComposer,
      $$IglesiasTableCreateCompanionBuilder,
      $$IglesiasTableUpdateCompanionBuilder,
      (Iglesia, $$IglesiasTableReferences),
      Iglesia,
      PrefetchHooks Function({bool feligresesRefs})
    >;
typedef $$FeligresesTableCreateCompanionBuilder =
    FeligresesCompanion Function({
      required String id,
      required String nombre,
      Value<DateTime?> fechaNacimiento,
      Value<String?> genero,
      Value<String?> telefono,
      Value<int> activo,
      Value<int> syncStatus,
      Value<String?> cedula,
      Value<String?> estadoCivil,
      Value<bool> poseeDiscapacidad,
      Value<bool> bautizadoAgua,
      Value<bool> bautizadoEspiritu,
      Value<String> tipoFeligres,
      Value<String?> iglesiaId,
      Value<int> rowid,
    });
typedef $$FeligresesTableUpdateCompanionBuilder =
    FeligresesCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<DateTime?> fechaNacimiento,
      Value<String?> genero,
      Value<String?> telefono,
      Value<int> activo,
      Value<int> syncStatus,
      Value<String?> cedula,
      Value<String?> estadoCivil,
      Value<bool> poseeDiscapacidad,
      Value<bool> bautizadoAgua,
      Value<bool> bautizadoEspiritu,
      Value<String> tipoFeligres,
      Value<String?> iglesiaId,
      Value<int> rowid,
    });

final class $$FeligresesTableReferences
    extends BaseReferences<_$AppDatabase, $FeligresesTable, Feligrese> {
  $$FeligresesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IglesiasTable _iglesiaIdTable(_$AppDatabase db) =>
      db.iglesias.createAlias(
        $_aliasNameGenerator(db.feligreses.iglesiaId, db.iglesias.id),
      );

  $$IglesiasTableProcessedTableManager? get iglesiaId {
    final $_column = $_itemColumn<String>('iglesia_id');
    if ($_column == null) return null;
    final manager = $$IglesiasTableTableManager(
      $_db,
      $_db.iglesias,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_iglesiaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AportesTable, List<Aporte>> _aportesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.aportes,
    aliasName: $_aliasNameGenerator(db.feligreses.id, db.aportes.feligresId),
  );

  $$AportesTableProcessedTableManager get aportesRefs {
    final manager = $$AportesTableTableManager(
      $_db,
      $_db.aportes,
    ).filter((f) => f.feligresId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_aportesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FeligresesTableFilterComposer
    extends Composer<_$AppDatabase, $FeligresesTable> {
  $$FeligresesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estadoCivil => $composableBuilder(
    column: $table.estadoCivil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get poseeDiscapacidad => $composableBuilder(
    column: $table.poseeDiscapacidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bautizadoAgua => $composableBuilder(
    column: $table.bautizadoAgua,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bautizadoEspiritu => $composableBuilder(
    column: $table.bautizadoEspiritu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipoFeligres => $composableBuilder(
    column: $table.tipoFeligres,
    builder: (column) => ColumnFilters(column),
  );

  $$IglesiasTableFilterComposer get iglesiaId {
    final $$IglesiasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.iglesiaId,
      referencedTable: $db.iglesias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IglesiasTableFilterComposer(
            $db: $db,
            $table: $db.iglesias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> aportesRefs(
    Expression<bool> Function($$AportesTableFilterComposer f) f,
  ) {
    final $$AportesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aportes,
      getReferencedColumn: (t) => t.feligresId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AportesTableFilterComposer(
            $db: $db,
            $table: $db.aportes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FeligresesTableOrderingComposer
    extends Composer<_$AppDatabase, $FeligresesTable> {
  $$FeligresesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genero => $composableBuilder(
    column: $table.genero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cedula => $composableBuilder(
    column: $table.cedula,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estadoCivil => $composableBuilder(
    column: $table.estadoCivil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get poseeDiscapacidad => $composableBuilder(
    column: $table.poseeDiscapacidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bautizadoAgua => $composableBuilder(
    column: $table.bautizadoAgua,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bautizadoEspiritu => $composableBuilder(
    column: $table.bautizadoEspiritu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipoFeligres => $composableBuilder(
    column: $table.tipoFeligres,
    builder: (column) => ColumnOrderings(column),
  );

  $$IglesiasTableOrderingComposer get iglesiaId {
    final $$IglesiasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.iglesiaId,
      referencedTable: $db.iglesias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IglesiasTableOrderingComposer(
            $db: $db,
            $table: $db.iglesias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeligresesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeligresesTable> {
  $$FeligresesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<DateTime> get fechaNacimiento => $composableBuilder(
    column: $table.fechaNacimiento,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genero =>
      $composableBuilder(column: $table.genero, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<int> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cedula =>
      $composableBuilder(column: $table.cedula, builder: (column) => column);

  GeneratedColumn<String> get estadoCivil => $composableBuilder(
    column: $table.estadoCivil,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get poseeDiscapacidad => $composableBuilder(
    column: $table.poseeDiscapacidad,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bautizadoAgua => $composableBuilder(
    column: $table.bautizadoAgua,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bautizadoEspiritu => $composableBuilder(
    column: $table.bautizadoEspiritu,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipoFeligres => $composableBuilder(
    column: $table.tipoFeligres,
    builder: (column) => column,
  );

  $$IglesiasTableAnnotationComposer get iglesiaId {
    final $$IglesiasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.iglesiaId,
      referencedTable: $db.iglesias,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IglesiasTableAnnotationComposer(
            $db: $db,
            $table: $db.iglesias,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> aportesRefs<T extends Object>(
    Expression<T> Function($$AportesTableAnnotationComposer a) f,
  ) {
    final $$AportesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.aportes,
      getReferencedColumn: (t) => t.feligresId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AportesTableAnnotationComposer(
            $db: $db,
            $table: $db.aportes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FeligresesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeligresesTable,
          Feligrese,
          $$FeligresesTableFilterComposer,
          $$FeligresesTableOrderingComposer,
          $$FeligresesTableAnnotationComposer,
          $$FeligresesTableCreateCompanionBuilder,
          $$FeligresesTableUpdateCompanionBuilder,
          (Feligrese, $$FeligresesTableReferences),
          Feligrese,
          PrefetchHooks Function({bool iglesiaId, bool aportesRefs})
        > {
  $$FeligresesTableTableManager(_$AppDatabase db, $FeligresesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeligresesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeligresesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeligresesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<int> activo = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> cedula = const Value.absent(),
                Value<String?> estadoCivil = const Value.absent(),
                Value<bool> poseeDiscapacidad = const Value.absent(),
                Value<bool> bautizadoAgua = const Value.absent(),
                Value<bool> bautizadoEspiritu = const Value.absent(),
                Value<String> tipoFeligres = const Value.absent(),
                Value<String?> iglesiaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeligresesCompanion(
                id: id,
                nombre: nombre,
                fechaNacimiento: fechaNacimiento,
                genero: genero,
                telefono: telefono,
                activo: activo,
                syncStatus: syncStatus,
                cedula: cedula,
                estadoCivil: estadoCivil,
                poseeDiscapacidad: poseeDiscapacidad,
                bautizadoAgua: bautizadoAgua,
                bautizadoEspiritu: bautizadoEspiritu,
                tipoFeligres: tipoFeligres,
                iglesiaId: iglesiaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<DateTime?> fechaNacimiento = const Value.absent(),
                Value<String?> genero = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<int> activo = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String?> cedula = const Value.absent(),
                Value<String?> estadoCivil = const Value.absent(),
                Value<bool> poseeDiscapacidad = const Value.absent(),
                Value<bool> bautizadoAgua = const Value.absent(),
                Value<bool> bautizadoEspiritu = const Value.absent(),
                Value<String> tipoFeligres = const Value.absent(),
                Value<String?> iglesiaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeligresesCompanion.insert(
                id: id,
                nombre: nombre,
                fechaNacimiento: fechaNacimiento,
                genero: genero,
                telefono: telefono,
                activo: activo,
                syncStatus: syncStatus,
                cedula: cedula,
                estadoCivil: estadoCivil,
                poseeDiscapacidad: poseeDiscapacidad,
                bautizadoAgua: bautizadoAgua,
                bautizadoEspiritu: bautizadoEspiritu,
                tipoFeligres: tipoFeligres,
                iglesiaId: iglesiaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FeligresesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({iglesiaId = false, aportesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aportesRefs) db.aportes],
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
                    if (iglesiaId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.iglesiaId,
                                referencedTable: $$FeligresesTableReferences
                                    ._iglesiaIdTable(db),
                                referencedColumn: $$FeligresesTableReferences
                                    ._iglesiaIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (aportesRefs)
                    await $_getPrefetchedData<
                      Feligrese,
                      $FeligresesTable,
                      Aporte
                    >(
                      currentTable: table,
                      referencedTable: $$FeligresesTableReferences
                          ._aportesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$FeligresesTableReferences(
                            db,
                            table,
                            p0,
                          ).aportesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.feligresId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FeligresesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeligresesTable,
      Feligrese,
      $$FeligresesTableFilterComposer,
      $$FeligresesTableOrderingComposer,
      $$FeligresesTableAnnotationComposer,
      $$FeligresesTableCreateCompanionBuilder,
      $$FeligresesTableUpdateCompanionBuilder,
      (Feligrese, $$FeligresesTableReferences),
      Feligrese,
      PrefetchHooks Function({bool iglesiaId, bool aportesRefs})
    >;
typedef $$AportesTableCreateCompanionBuilder =
    AportesCompanion Function({
      required String id,
      required String feligresId,
      required double monto,
      required String tipo,
      Value<DateTime> fecha,
      Value<int> syncStatus,
      Value<int> rowid,
    });
typedef $$AportesTableUpdateCompanionBuilder =
    AportesCompanion Function({
      Value<String> id,
      Value<String> feligresId,
      Value<double> monto,
      Value<String> tipo,
      Value<DateTime> fecha,
      Value<int> syncStatus,
      Value<int> rowid,
    });

final class $$AportesTableReferences
    extends BaseReferences<_$AppDatabase, $AportesTable, Aporte> {
  $$AportesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FeligresesTable _feligresIdTable(_$AppDatabase db) =>
      db.feligreses.createAlias(
        $_aliasNameGenerator(db.aportes.feligresId, db.feligreses.id),
      );

  $$FeligresesTableProcessedTableManager get feligresId {
    final $_column = $_itemColumn<String>('feligres_id')!;

    final manager = $$FeligresesTableTableManager(
      $_db,
      $_db.feligreses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_feligresIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AportesTableFilterComposer
    extends Composer<_$AppDatabase, $AportesTable> {
  $$AportesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$FeligresesTableFilterComposer get feligresId {
    final $$FeligresesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feligresId,
      referencedTable: $db.feligreses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeligresesTableFilterComposer(
            $db: $db,
            $table: $db.feligreses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AportesTableOrderingComposer
    extends Composer<_$AppDatabase, $AportesTable> {
  $$AportesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monto => $composableBuilder(
    column: $table.monto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$FeligresesTableOrderingComposer get feligresId {
    final $$FeligresesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feligresId,
      referencedTable: $db.feligreses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeligresesTableOrderingComposer(
            $db: $db,
            $table: $db.feligreses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AportesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AportesTable> {
  $$AportesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get monto =>
      $composableBuilder(column: $table.monto, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$FeligresesTableAnnotationComposer get feligresId {
    final $$FeligresesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.feligresId,
      referencedTable: $db.feligreses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeligresesTableAnnotationComposer(
            $db: $db,
            $table: $db.feligreses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AportesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AportesTable,
          Aporte,
          $$AportesTableFilterComposer,
          $$AportesTableOrderingComposer,
          $$AportesTableAnnotationComposer,
          $$AportesTableCreateCompanionBuilder,
          $$AportesTableUpdateCompanionBuilder,
          (Aporte, $$AportesTableReferences),
          Aporte,
          PrefetchHooks Function({bool feligresId})
        > {
  $$AportesTableTableManager(_$AppDatabase db, $AportesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AportesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AportesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AportesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> feligresId = const Value.absent(),
                Value<double> monto = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AportesCompanion(
                id: id,
                feligresId: feligresId,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String feligresId,
                required double monto,
                required String tipo,
                Value<DateTime> fecha = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AportesCompanion.insert(
                id: id,
                feligresId: feligresId,
                monto: monto,
                tipo: tipo,
                fecha: fecha,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AportesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({feligresId = false}) {
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
                    if (feligresId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.feligresId,
                                referencedTable: $$AportesTableReferences
                                    ._feligresIdTable(db),
                                referencedColumn: $$AportesTableReferences
                                    ._feligresIdTable(db)
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

typedef $$AportesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AportesTable,
      Aporte,
      $$AportesTableFilterComposer,
      $$AportesTableOrderingComposer,
      $$AportesTableAnnotationComposer,
      $$AportesTableCreateCompanionBuilder,
      $$AportesTableUpdateCompanionBuilder,
      (Aporte, $$AportesTableReferences),
      Aporte,
      PrefetchHooks Function({bool feligresId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IglesiasTableTableManager get iglesias =>
      $$IglesiasTableTableManager(_db, _db.iglesias);
  $$FeligresesTableTableManager get feligreses =>
      $$FeligresesTableTableManager(_db, _db.feligreses);
  $$AportesTableTableManager get aportes =>
      $$AportesTableTableManager(_db, _db.aportes);
}
