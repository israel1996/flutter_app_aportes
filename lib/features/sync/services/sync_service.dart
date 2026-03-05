import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';

class SyncService {
  final AppDatabase localDb;
  final SupabaseClient cloudDb;

  SyncService(this.localDb) : cloudDb = Supabase.instance.client;

  Future<void> syncAll() async {
    final session = cloudDb.auth.currentSession;

    if (session == null || session.isExpired) {
      debugPrint("⚠️ No active session yet. Skipping cloud sync for now.");
      return;
    }

    await pushLocalChanges();
    await pullFromCloud();
  }

  Future<void> pushLocalChanges() async {
    final currentUser = cloudDb.auth.currentUser;
    if (currentUser == null) return;

    // 1. SYNC CHURCHES
    final pendingIglesias = await (localDb.select(
      localDb.iglesias,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();
    for (var iglesia in pendingIglesias) {
      try {
        await cloudDb.from('iglesias').upsert({
          'id': iglesia.id,
          'user_id': currentUser.id, // Assign to current pastor
          'nombre': iglesia.nombre,
          'distrito': iglesia.distrito,
          'fecha_llegada': iglesia.fechaLlegada?.toIso8601String(),
          'fecha_salida': iglesia.fechaSalida?.toIso8601String(),
          'categoria': iglesia.categoria,
          'sync_status': 1,
        });
        await (localDb.update(localDb.iglesias)
              ..where((tbl) => tbl.id.equals(iglesia.id)))
            .write(IglesiasCompanion(syncStatus: const drift.Value(1)));
        debugPrint("Uploaded Church: ${iglesia.nombre}");
      } catch (e) {
        debugPrint("Error pushing church: $e");
      }
    }

    final pendingMembers = await (localDb.select(
      localDb.feligreses,
    )..where((tbl) => tbl.syncStatus.equals(0))).get();

    for (var person in pendingMembers) {
      try {
        await cloudDb.from('feligreses').upsert({
          'id': person.id,
          'nombre': person.nombre,
          'telefono': person.telefono,
          'genero': person.genero,
          'fechanacimiento': person.fechaNacimiento?.toIso8601String(),
          'activo': person.activo,
          'cedula': person.cedula,
          'estado_civil': person.estadoCivil,
          'tipo_feligres': person.tipoFeligres,
          'posee_discapacidad': person.poseeDiscapacidad,
          'bautizado_agua': person.bautizadoAgua,
          'bautizado_espiritu': person.bautizadoEspiritu,
          'iglesia_id': person.iglesiaId,
        });
        await (localDb.update(localDb.feligreses)
              ..where((tbl) => tbl.id.equals(person.id)))
            .write(FeligresesCompanion(syncStatus: const drift.Value(1)));
        debugPrint("Uploaded: ${person.nombre}");
      } catch (e) {
        debugPrint("Error pushing member ${person.nombre}: $e");
      }
    }

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

        await (localDb.update(localDb.aportes)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(AportesCompanion(syncStatus: const drift.Value(1)));
        debugPrint("Uploaded Tithe: \$${item.monto}");
      } catch (e) {
        debugPrint("Error pushing tithe: $e");
      }
    }
  }

  Future<void> pullFromCloud() async {
    try {
      final currentUser = cloudDb.auth.currentUser;
      if (currentUser == null) throw Exception("User not logged in");
      // 1. PULL ONLY THIS USER'S CHURCHES
      final List<dynamic> cloudIglesias = await cloudDb
          .from('iglesias')
          .select()
          .eq('user_id', currentUser.id); // Filter by pastor

      debugPrint("Downloaded ${cloudIglesias.length} iglesias from cloud.");

      for (var data in cloudIglesias) {
        await localDb
            .into(localDb.iglesias)
            .insertOnConflictUpdate(
              IglesiasCompanion(
                id: drift.Value(data['id']),
                userId: drift.Value(data['user_id']),
                nombre: drift.Value(data['nombre']),
                distrito: drift.Value(data['distrito']),
                categoria: drift.Value(data['categoria']),
                fechaLlegada: drift.Value(
                  data['fecha_llegada'] != null
                      ? DateTime.parse(data['fecha_llegada'])
                      : null,
                ),
                fechaSalida: drift.Value(
                  data['fecha_salida'] != null
                      ? DateTime.parse(data['fecha_salida'])
                      : null,
                ),
                syncStatus: const drift.Value(1),
              ),
            );
      }

      final List<dynamic> cloudMembers = await cloudDb
          .from('feligreses')
          .select();

      debugPrint("Downloaded ${cloudMembers.length} members from cloud.");

      for (var data in cloudMembers) {
        await localDb
            .into(localDb.feligreses)
            .insertOnConflictUpdate(
              FeligresesCompanion(
                id: drift.Value(data['id']),
                nombre: drift.Value(data['nombre']),
                telefono: drift.Value(data['telefono']),
                activo: drift.Value(
                  data['activo'] == 1 || data['activo'] == true ? 1 : 0,
                ),
                syncStatus: const drift.Value(1),
                genero: drift.Value(data['genero']),
                fechaNacimiento: drift.Value(
                  data['fechanacimiento'] != null
                      ? DateTime.tryParse(data['fechanacimiento'].toString())
                      : null,
                ),
                cedula: drift.Value(data['cedula']),
                estadoCivil: drift.Value(data['estado_civil']),
                tipoFeligres: drift.Value(data['tipo_feligres']),
                poseeDiscapacidad: drift.Value(data['posee_discapacidad']),
                bautizadoAgua: drift.Value(data['bautizado_agua']),
                bautizadoEspiritu: drift.Value(data['bautizado_espiritu']),
                iglesiaId: drift.Value(data['iglesia_id']),
              ),
            );
      }

      debugPrint("Local DB updated successfully.");

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
