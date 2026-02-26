import 'package:drift/drift.dart';
import 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart'
    as impl;

part 'database.g.dart';

class Feligreses extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text().withLength(min: 1, max: 100)();
  DateTimeColumn get fechaNacimiento => dateTime().nullable()();
  TextColumn get genero => text().nullable()();
  TextColumn get telefono => text().nullable()();
  IntColumn get activo => integer().withDefault(const Constant(1))();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Aportes extends Table {
  TextColumn get id => text()();
  TextColumn get feligresId => text().references(Feligreses, #id)();
  RealColumn get monto => real()();
  TextColumn get tipo => text()();
  DateTimeColumn get fecha => dateTime().clientDefault(() => DateTime.now())();

  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class AporteConFeligres {
  final Aporte aporte;
  final Feligrese feligres;
  AporteConFeligres(this.aporte, this.feligres);
}

@DriftDatabase(tables: [Feligreses, Aportes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 2;

  Stream<List<Feligrese>> watchAllFeligreses() {
    return select(feligreses).watch();
  }

  Future<int> insertFeligres(FeligresesCompanion entry) {
    return into(feligreses).insert(entry);
  }

  Future<bool> updateFeligres(FeligresesCompanion entry) {
    return update(feligreses).replace(entry);
  }

  Future<int> deleteFeligres(String id) async {
    return (update(feligreses)..where((tbl) => tbl.id.equals(id))).write(
      const FeligresesCompanion(activo: Value(0), syncStatus: Value(0)),
    );
  }

  Stream<List<AporteConFeligres>> watchHistory() {
    final query = select(aportes).join([
      innerJoin(feligreses, feligreses.id.equalsExp(aportes.feligresId)),
    ]);
    query.orderBy([OrderingTerm.desc(aportes.fecha)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return AporteConFeligres(
          row.readTable(aportes),
          row.readTable(feligreses),
        );
      }).toList();
    });
  }

  Future<int> insertAporte(AportesCompanion entry) {
    return into(aportes).insert(entry);
  }

  Future<bool> updateAporte(AportesCompanion entry) {
    return update(aportes).replace(entry);
  }

  Future<int> deleteAporte(String id) {
    return (delete(aportes)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<double> watchTotalIncome() {
    final sumExpr = aportes.monto.sum();
    final query = selectOnly(aportes)..addColumns([sumExpr]);

    return query.watchSingle().map((row) => row.read(sumExpr) ?? 0.0);
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      await delete(aportes).go();
      await delete(feligreses).go();
    });
  }

  Future<bool> hasPendingSyncs() async {
    final pendingAportes = await (select(
      aportes,
    )..where((a) => a.syncStatus.equals(0))).get();
    final pendingFeligreses = await (select(
      feligreses,
    )..where((f) => f.syncStatus.equals(0))).get();

    return pendingAportes.isNotEmpty || pendingFeligreses.isNotEmpty;
  }
}
