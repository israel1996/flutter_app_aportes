import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/database.dart';

class SyncService {
  final AppDatabase database;
  final SupabaseClient _supabase = Supabase.instance.client;

  SyncService(this.database);

  Future<void> syncAll() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);

    if (!hasInternet || _supabase.auth.currentUser == null) return;

    await Future.microtask(() async {
      try {
        debugPrint("--- STARTING HIGH-PERFORMANCE DELTA SYNC ---");

        await _pushLocalChanges();

        final prefs = await SharedPreferences.getInstance();
        final lastSyncStr = prefs.getString('last_sync_time');

        await _pullIglesias(lastSyncStr);
        await _pullFeligreses(lastSyncStr);
        await _pullAportes(lastSyncStr);

        final now = DateTime.now().toUtc().toIso8601String();
        await prefs.setString('last_sync_time', now);

        debugPrint("--- DELTA SYNC COMPLETE ---");
      } catch (e) {
        debugPrint("Background sync failed: $e");
      }
    });
  }

  // =========================================================================
  // PUSH PHASE - EL SERVIDOR (SUPABASE) SE ENCARGA DE LAS FECHAS DE REGISTRO
  // =========================================================================

  Future<void> _pushLocalChanges() async {
    await _pushIglesias();
    await _pushFeligreses();
    await _pushAportes();
  }

  Future<void> _pushIglesias() async {
    final pending = await (database.select(
      database.iglesias,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (final local in pending) {
      try {
        await _supabase.from('iglesias').upsert({
          'id': local.id,
          'nombre': local.nombre,
          'distrito': local.distrito,
          'categoria': local.categoria,
          'fecha_llegada': local.fechaLlegada?.toUtc().toIso8601String(),
          'fecha_salida': local.fechaSalida?.toUtc().toIso8601String(),
          'user_id': _supabase.auth.currentUser!.id,
          'is_deleted': false,
          // created_at y updated_at son generados por Supabase
        });

        await (database.update(database.iglesias)
              ..where((tbl) => tbl.id.equals(local.id)))
            .write(const IglesiasCompanion(syncStatus: drift.Value(1)));
      } catch (e) {
        debugPrint("Push Iglesia Error: $e");
      }
    }
  }

  Future<void> _pushFeligreses() async {
    final pending = await (database.select(
      database.feligreses,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (final local in pending) {
      try {
        await _supabase.from('feligreses').upsert({
          'id': local.id,
          'iglesia_id': local.iglesiaId,
          'user_id': _supabase.auth.currentUser!.id,
          'nombre': local.nombre,
          'genero': local.genero,
          'telefono': local.telefono,
          'fechanacimiento': local.fechaNacimiento?.toUtc().toIso8601String(),
          'cedula': local.cedula,
          'estado_civil': local.estadoCivil,
          'posee_discapacidad': local.poseeDiscapacidad,
          'bautizado_agua': local.bautizadoAgua,
          'bautizado_espiritu': local.bautizadoEspiritu,
          'tipo_feligres': local.tipoFeligres,
          'activo': local.activo,
          // created_at y updated_at son generados por Supabase
        });

        await (database.update(database.feligreses)
              ..where((tbl) => tbl.id.equals(local.id)))
            .write(const FeligresesCompanion(syncStatus: drift.Value(1)));
      } catch (e) {
        debugPrint("Push Feligres Error: $e");
      }
    }
  }

  Future<void> _pushAportes() async {
    final pending = await (database.select(
      database.aportes,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (final local in pending) {
      try {
        await _supabase.from('aportes').upsert({
          'id': local.id,
          'feligres_id': local.feligresId,
          'user_id': _supabase.auth.currentUser!.id,
          'monto': local.monto,
          'tipo': local.tipo,
          'fecha': local.fecha.toUtc().toIso8601String(),
          'is_deleted': false,
          // created_at y updated_at son generados por Supabase
        });

        await (database.update(database.aportes)
              ..where((tbl) => tbl.id.equals(local.id)))
            .write(const AportesCompanion(syncStatus: drift.Value(1)));
      } catch (e) {
        debugPrint("Push Aporte Error: $e");
      }
    }
  }

  // =========================================================================
  // PULL PHASE - CONVERSIÓN A HORA LOCAL ECUADOR (.toLocal)
  // =========================================================================

  Future<void> _pullIglesias(String? lastSyncStr) async {
    var query = _supabase
        .from('iglesias')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id);
    if (lastSyncStr != null) {
      query = query.gt('updated_at', lastSyncStr);
    }

    final List<dynamic> cloudData = await query;
    if (cloudData.isEmpty) return;

    await database.batch((batch) {
      for (final row in cloudData) {
        try {
          if (row['is_deleted'] == true) {
            batch.deleteWhere(
              database.iglesias,
              (tbl) => tbl.id.equals(row['id']),
            );
          } else {
            batch.insert(
              database.iglesias,
              IglesiasCompanion.insert(
                id: row['id'],
                userId: row['user_id'],
                nombre: row['nombre'],
                distrito: row['distrito'],
                categoria: drift.Value(row['categoria']),
                fechaLlegada: drift.Value(
                  row['fecha_llegada'] != null
                      ? DateTime.parse(row['fecha_llegada']).toLocal()
                      : null,
                ),
                fechaSalida: drift.Value(
                  row['fecha_salida'] != null
                      ? DateTime.parse(row['fecha_salida']).toLocal()
                      : null,
                ),
                syncStatus: const drift.Value(1),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
          }
        } catch (e) {
          debugPrint("Skipping bad Iglesia row ${row['id']}: $e");
        }
      }
    });
  }

  Future<void> _pullFeligreses(String? lastSyncStr) async {
    var query = _supabase
        .from('feligreses')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id);
    if (lastSyncStr != null) {
      query = query.gt('updated_at', lastSyncStr);
    }

    final List<dynamic> cloudData = await query;
    if (cloudData.isEmpty) return;

    await database.batch((batch) {
      for (final row in cloudData) {
        try {
          batch.insert(
            database.feligreses,
            FeligresesCompanion.insert(
              id: row['id'],
              iglesiaId: drift.Value(row['iglesia_id']),
              nombre: row['nombre'] ?? 'Sin Nombre',
              telefono: drift.Value(row['telefono']),
              fechaNacimiento: drift.Value(
                row['fechanacimiento'] != null
                    ? DateTime.parse(row['fechanacimiento']).toLocal()
                    : null,
              ),
              genero: drift.Value(row['genero']),
              cedula: drift.Value(row['cedula']),
              estadoCivil: drift.Value(row['estado_civil']),
              poseeDiscapacidad: drift.Value(
                row['posee_discapacidad'] ?? false,
              ),
              bautizadoAgua: drift.Value(row['bautizado_agua'] ?? false),
              bautizadoEspiritu: drift.Value(
                row['bautizado_espiritu'] ?? false,
              ),
              tipoFeligres: drift.Value(row['tipo_feligres']),
              activo: drift.Value(row['activo'] ?? 1),
              fechaRegistro: drift.Value(
                row['created_at'] != null
                    ? DateTime.parse(row['created_at']).toLocal()
                    : null,
              ),
              fechaModificacion: drift.Value(
                row['updated_at'] != null
                    ? DateTime.parse(row['updated_at']).toLocal()
                    : null,
              ),
              syncStatus: const drift.Value(1),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        } catch (e) {
          debugPrint("Skipping bad Feligres row ${row['id']}: $e");
        }
      }
    });
  }

  Future<void> _pullAportes(String? lastSyncStr) async {
    var query = _supabase
        .from('aportes')
        .select()
        .eq('user_id', _supabase.auth.currentUser!.id);
    if (lastSyncStr != null) {
      query = query.gt('updated_at', lastSyncStr);
    }

    final List<dynamic> cloudData = await query;
    if (cloudData.isEmpty) return;

    await database.batch((batch) {
      for (final row in cloudData) {
        try {
          if (row['is_deleted'] == true) {
            batch.deleteWhere(
              database.aportes,
              (tbl) => tbl.id.equals(row['id']),
            );
          } else {
            batch.insert(
              database.aportes,
              AportesCompanion.insert(
                id: row['id'],
                feligresId: row['feligres_id'],
                monto: double.tryParse(row['monto']?.toString() ?? '0') ?? 0.0,
                tipo: row['tipo'] ?? 'Desconocido',
                fecha: drift.Value(
                  row['fecha'] != null
                      ? DateTime.parse(row['fecha']).toLocal()
                      : DateTime.now(),
                ),
                fechaRegistro: drift.Value(
                  row['created_at'] != null
                      ? DateTime.parse(row['created_at']).toLocal()
                      : null,
                ),
                fechaModificacion: drift.Value(
                  row['updated_at'] != null
                      ? DateTime.parse(row['updated_at']).toLocal()
                      : null,
                ),
                syncStatus: const drift.Value(1),
              ),
              mode: drift.InsertMode.insertOrReplace,
            );
          }
        } catch (e) {
          debugPrint("Skipping bad Aporte row ${row['id']}: $e");
        }
      }
    });
  }
}
