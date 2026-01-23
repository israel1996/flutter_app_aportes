import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// TABLA 1: FELIGRESES
class Feligreses extends Table {
  TextColumn get id => text()(); // UUID único
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  TextColumn get telefono => text().nullable()();
  // 0 = Pendiente de subir, 1 = Sincronizado
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// TABLA 2: APORTES (DIEZMOS)
class Aportes extends Table {
  TextColumn get id => text()();
  TextColumn get feligresId => text().references(Feligreses, #id)();
  RealColumn get monto => real()(); // Dinero
  TextColumn get tipo => text()(); // "Diezmo", "Ofrenda", etc.
  DateTimeColumn get fecha => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// EL CEREBRO DE LA BASE DE DATOS
@DriftDatabase(tables: [Feligreses, Aportes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// FUNCIÓN PARA ABRIR LA CONEXIÓN EN WINDOWS Y ANDROID
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db_iglesia.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
