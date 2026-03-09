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

  /// Main entry point for the Delta Sync architecture
  Future<void> syncAll() async {
    final connectivity = await Connectivity().checkConnectivity();
    final hasInternet =
        connectivity.contains(ConnectivityResult.mobile) ||
        connectivity.contains(ConnectivityResult.wifi) ||
        connectivity.contains(ConnectivityResult.ethernet);

    if (!hasInternet || _supabase.auth.currentUser == null) return;

    // Yield the thread to prevent UI freezing
    await Future.microtask(() async {
      try {
        debugPrint("--- STARTING DELTA SYNC ---");

        // 1. PUSH: Upload local changes to the cloud first
        await _pushLocalChanges();

        // 2. GET TIMESTAMP: Retrieve the exact time of the last sync
        final prefs = await SharedPreferences.getInstance();
        final lastSyncStr = prefs.getString('last_sync_time');

        // 3. PULL: Download only the data modified AFTER the last sync
        await _pullIglesias(lastSyncStr);
        await _pullFeligreses(lastSyncStr);
        await _pullAportes(lastSyncStr);

        // 4. UPDATE TIMESTAMP: Save the new sync time
        final now = DateTime.now().toUtc().toIso8601String();
        await prefs.setString('last_sync_time', now);

        debugPrint("--- DELTA SYNC COMPLETE ---");
      } catch (e) {
        debugPrint("Background sync failed: $e");
      }
    });
  }

  // =========================================================================
  // PUSH PHASE (Local to Cloud)
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
          'fecha_llegada': local.fechaLlegada?.toIso8601String(),
          'fecha_salida': local.fechaSalida?.toIso8601String(),
          'user_id': _supabase.auth.currentUser!.id,
          'is_deleted': false, // Soft delete flag
        });

        // Mark as synced locally
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
          'fechanacimiento': local.fechaNacimiento?.toIso8601String(),
          'cedula': local.cedula,
          'estado_civil': local.estadoCivil,
          'posee_discapacidad': local.poseeDiscapacidad,
          'bautizado_agua': local.bautizadoAgua,
          'bautizado_espiritu': local.bautizadoEspiritu,
          'tipo_feligres': local.tipoFeligres,
          'activo': local.activo,
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
          'fecha': local.fecha.toIso8601String(),
          'is_deleted': false,
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
  // PULL PHASE (Cloud to Local - DELTA SYNC)
  // =========================================================================

  Future<void> _pullIglesias(String? lastSyncStr) async {
    // FIX: Filter strictly by the logged-in user's ID
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
                    ? DateTime.parse(row['fecha_llegada'])
                    : null,
              ),
              fechaSalida: drift.Value(
                row['fecha_salida'] != null
                    ? DateTime.parse(row['fecha_salida'])
                    : null,
              ),
              syncStatus: const drift.Value(1),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  Future<void> _pullFeligreses(String? lastSyncStr) async {
    // FIX: Filter strictly by the logged-in user's ID
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
        batch.insert(
          database.feligreses,
          FeligresesCompanion.insert(
            id: row['id'],
            iglesiaId: drift.Value(row['iglesia_id']),
            nombre: row['nombre'],
            telefono: drift.Value(row['telefono']),
            fechaNacimiento: drift.Value(
              row['fechanacimiento'] != null
                  ? DateTime.parse(row['fechanacimiento'])
                  : null,
            ),
            genero: drift.Value(row['genero']),
            cedula: drift.Value(row['cedula']),
            estadoCivil: drift.Value(row['estado_civil']),
            poseeDiscapacidad: drift.Value(row['posee_discapacidad'] ?? false),
            bautizadoAgua: drift.Value(row['bautizado_agua'] ?? false),
            bautizadoEspiritu: drift.Value(row['bautizado_espiritu'] ?? false),
            tipoFeligres: drift.Value(row['tipo_feligres']),
            activo: drift.Value(
              row['activo'],
            ), // Handles Soft Deletes automatically
            syncStatus: const drift.Value(1),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _pullAportes(String? lastSyncStr) async {
    // FIX: Filter strictly by the logged-in user's ID
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
              monto: (row['monto'] as num).toDouble(),
              tipo: row['tipo'],
              fecha: drift.Value(DateTime.parse(row['fecha'])),
              syncStatus: const drift.Value(1),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      }
    });
  }
}
