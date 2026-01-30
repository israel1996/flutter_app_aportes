import 'package:drift/drift.dart';
import 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart'
    as impl;

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

class AporteConFeligres {
  final Aporte aporte;
  final Feligrese feligres;
  AporteConFeligres(this.aporte, this.feligres);
}

// EL CEREBRO DE LA BASE DE DATOS
@DriftDatabase(tables: [Feligreses, Aportes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  @override
  int get schemaVersion => 1;

  // CONNECT TABLES: Join Aportes with Feligreses
  Stream<List<AporteConFeligres>> watchHistory() {
    final query = select(aportes).join([
      // Join rule: The ID in Aportes matches the ID in Feligreses
      innerJoin(feligreses, feligreses.id.equalsExp(aportes.feligresId)),
    ]);

    // Order by Date (Newest first)
    query.orderBy([OrderingTerm.desc(aportes.fecha)]);

    // Transform the raw rows into our nice custom class
    return query.watch().map((rows) {
      return rows.map((row) {
        return AporteConFeligres(
          row.readTable(aportes),
          row.readTable(feligreses),
        );
      }).toList();
    });
  }

  Stream<List<Feligrese>> watchAllFeligreses() {
    return select(feligreses).watch();
  }

  // Calculate Total Income
  Stream<double> watchTotalIncome() {
    final sumExpr = aportes.monto.sum();
    final query = selectOnly(aportes)..addColumns([sumExpr]);

    return query.watchSingle().map((row) => row.read(sumExpr) ?? 0.0);
  }
}
