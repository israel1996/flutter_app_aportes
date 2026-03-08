import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/database/database.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

enum AppEnvironment { finanzas, secretaria }

final environmentProvider = StateProvider<AppEnvironment>((ref) {
  return AppEnvironment.finanzas;
});

// --- NEW LOGIC: PERSISTENT CHURCH SELECTION ---
class CurrentIglesiaNotifier extends StateNotifier<Iglesia?> {
  final Ref ref;
  String?
  _cloudPreferenceId; // Variable en memoria para guardar el ID de la nube

  CurrentIglesiaNotifier(this.ref) : super(null) {
    _loadCloudPreference();
  }

  // 1. Obtener la última sede seleccionada desde la nube al iniciar
  Future<void> _loadCloudPreference() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userData = await supabase
          .from('usuarios_app')
          .select('ultima_iglesia_id')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null && userData['ultima_iglesia_id'] != null) {
        _cloudPreferenceId = userData['ultima_iglesia_id'];
      }
    } catch (e) {
      // Ignorar errores en segundo plano
    }
  }

  // NUEVO MÉTODO: Llamado por HomeScreen cuando las iglesias terminan de cargar localmente
  void setIglesiaFromListSafe(List<Iglesia> iglesias) {
    if (state != null) return; // Si ya hay una seleccionada, no hacer nada
    if (iglesias.isEmpty) return;

    // 1. Intentar aplicar la preferencia guardada en la nube
    if (_cloudPreferenceId != null) {
      try {
        final match = iglesias.firstWhere((i) => i.id == _cloudPreferenceId);
        super.state =
            match; // Actualizar UI silenciosamente sin sobreescribir la nube
        return;
      } catch (e) {
        // La iglesia aún no se encuentra localmente, continuar al fallback
      }
    }

    // 2. Fallback: Seleccionar la primera disponible y respaldarla
    super.state = iglesias.first;
    _updateCloudPreference(iglesias.first.id);
  }

  // 2. Sobrescribir el setter para actualizar la nube automáticamente
  @override
  set state(Iglesia? value) {
    super.state = value; // Actualiza la UI instantáneamente

    if (value != null) {
      _cloudPreferenceId = value.id; // Actualiza la memoria local
      _updateCloudPreference(value.id); // Sube el cambio a la nube
    }
  }

  Future<void> _updateCloudPreference(String churchId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Actualizar Supabase en segundo plano
      await supabase
          .from('usuarios_app')
          .update({'ultima_iglesia_id': churchId})
          .eq('id', user.id);
    } catch (e) {
      // Ignorar errores en segundo plano
    }
  }
}

// Reemplazar el antiguo StateProvider con el nuevo StateNotifierProvider
final currentIglesiaProvider =
    StateNotifierProvider<CurrentIglesiaNotifier, Iglesia?>((ref) {
      return CurrentIglesiaNotifier(ref);
    });
