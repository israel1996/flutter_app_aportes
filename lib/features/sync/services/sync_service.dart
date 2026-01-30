import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift; // Alias for Drift helpers
import '../../../core/database/database.dart'; // Check your path

class SyncService {
  final AppDatabase localDb;
  final SupabaseClient cloudDb;

  SyncService(this.localDb) : cloudDb = Supabase.instance.client;

  // --- MAIN FUNCTION: SYNC EVERYTHING ---
  Future<void> syncAll() async {
    // 1. First, send our changes (Push)
    await pushLocalChanges();

    // 2. Then, download external changes (Pull)
    await pullFromCloud();
  }

  // --- PART A: PUSH (Local -> Cloud) ---
  Future<void> pushLocalChanges() async {
    // 1. Get Pending Members
    final pendingMembers = await (localDb.select(
      localDb.feligreses,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (var person in pendingMembers) {
      try {
        // Upsert to Supabase (User .upsert to avoid errors if ID exists)
        await cloudDb.from('feligreses').upsert({
          'id': person.id,
          'nombre': person.nombre,
          'telefono': person.telefono,
          // We can add 'updated_at': DateTime.now().toIso8601String(),
        });

        // Mark as Synced locally
        await (localDb.update(localDb.feligreses)
              ..where((tbl) => tbl.id.equals(person.id)))
            .write(FeligresesCompanion(syncStatus: const drift.Value(1)));
        debugPrint("Uploaded: ${person.nombre}");
      } catch (e) {
        debugPrint("Error pushing member ${person.nombre}: $e");
      }
    }

    // 2. SYNC TITHES (Children)
    final pendingAportes = await (localDb.select(
      localDb.aportes,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (var item in pendingAportes) {
      try {
        await cloudDb.from('aportes').upsert({
          'id': item.id,
          'feligres_id': item.feligresId,
          'monto': item.monto,
          'tipo': item.tipo,
          'fecha': item.fecha.toIso8601String(),
        });

        // Mark as Synced
        await (localDb.update(localDb.aportes)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(AportesCompanion(syncStatus: const drift.Value(1)));
        debugPrint("Uploaded Tithe: \$${item.monto}");
      } catch (e) {
        debugPrint("Error pushing tithe: $e");
        // Tip: If this fails, it's usually because the feligres_id wasn't found in cloud
      }
    }
  }

  // --- PART B: PULL (Cloud -> Local) ---
  Future<void> pullFromCloud() async {
    try {
      // 1. Fetch ALL members from Supabase
      // (In the future, you can filter by 'updated_at' for efficiency)
      final List<dynamic> cloudMembers = await cloudDb
          .from('feligreses')
          .select();

      debugPrint("Downloaded ${cloudMembers.length} members from cloud.");

      // 2. Save them to Local DB
      for (var data in cloudMembers) {
        await localDb
            .into(localDb.feligreses)
            .insertOnConflictUpdate(
              FeligresesCompanion(
                id: drift.Value(data['id']),
                nombre: drift.Value(data['nombre']),
                telefono: drift.Value(data['telefono']),
                syncStatus: const drift.Value(
                  1,
                ), // It comes from cloud, so it is synced
              ),
            );
      }

      debugPrint("Local DB updated successfully.");

      // 2. PULL TITHES
      final List<dynamic> cloudAportes = await cloudDb.from('aportes').select();

      for (var data in cloudAportes) {
        await localDb
            .into(localDb.aportes)
            .insertOnConflictUpdate(
              AportesCompanion(
                id: drift.Value(data['id']),
                feligresId: drift.Value(data['feligres_id']),
                monto: drift.Value(
                  data['monto'] is int
                      ? (data['monto'] as int).toDouble()
                      : data['monto'],
                ), // Handle numeric conversion safely
                tipo: drift.Value(data['tipo']),
                fecha: drift.Value(DateTime.parse(data['fecha'])),
                syncStatus: const drift.Value(1), // Synced!
              ),
            );
      }
      debugPrint("Tithes downloaded successfully.");
    } catch (e) {
      debugPrint("Error pulling data: $e");
      rethrow; // Pass the error to the UI
    }
  }
}
