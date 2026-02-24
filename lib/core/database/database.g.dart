// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    fechaNacimiento,
    genero,
    telefono,
    activo,
    syncStatus,
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
  const Feligrese({
    required this.id,
    required this.nombre,
    this.fechaNacimiento,
    this.genero,
    this.telefono,
    required this.activo,
    required this.syncStatus,
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
          ..write('syncStatus: $syncStatus')
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
          other.syncStatus == this.syncStatus);
}

class FeligresesCompanion extends UpdateCompanion<Feligrese> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<DateTime?> fechaNacimiento;
  final Value<String?> genero;
  final Value<String?> telefono;
  final Value<int> activo;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const FeligresesCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fechaNacimiento = const Value.absent(),
    this.genero = const Value.absent(),
    this.telefono = const Value.absent(),
    this.activo = const Value.absent(),
    this.syncStatus = const Value.absent(),
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
  late final $FeligresesTable feligreses = $FeligresesTable(this);
  late final $AportesTable aportes = $AportesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [feligreses, aportes];
}

typedef $$FeligresesTableCreateCompanionBuilder =
    FeligresesCompanion Function({
      required String id,
      required String nombre,
      Value<DateTime?> fechaNacimiento,
      Value<String?> genero,
      Value<String?> telefono,
      Value<int> activo,
      Value<int> syncStatus,
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
      Value<int> rowid,
    });

final class $$FeligresesTableReferences
    extends BaseReferences<_$AppDatabase, $FeligresesTable, Feligrese> {
  $$FeligresesTableReferences(super.$_db, super.$_table, super.$_typedResult);

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
          PrefetchHooks Function({bool aportesRefs})
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
                Value<int> rowid = const Value.absent(),
              }) => FeligresesCompanion(
                id: id,
                nombre: nombre,
                fechaNacimiento: fechaNacimiento,
                genero: genero,
                telefono: telefono,
                activo: activo,
                syncStatus: syncStatus,
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
                Value<int> rowid = const Value.absent(),
              }) => FeligresesCompanion.insert(
                id: id,
                nombre: nombre,
                fechaNacimiento: fechaNacimiento,
                genero: genero,
                telefono: telefono,
                activo: activo,
                syncStatus: syncStatus,
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
          prefetchHooksCallback: ({aportesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (aportesRefs) db.aportes],
              addJoins: null,
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
      PrefetchHooks Function({bool aportesRefs})
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
  $$FeligresesTableTableManager get feligreses =>
      $$FeligresesTableTableManager(_db, _db.feligreses);
  $$AportesTableTableManager get aportes =>
      $$AportesTableTableManager(_db, _db.aportes);
}
