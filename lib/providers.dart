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

  CurrentIglesiaNotifier(this.ref) : super(null) {
    _loadCloudPreference();
  }

  // 1. Fetch the last selected church from the cloud on startup|
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
        final db = ref.read(databaseProvider);

        // Look for that specific church in the local SQLite database
        final savedIglesia =
            await (db.select(
                  db.iglesias,
                )..where((tbl) => tbl.id.equals(userData['ultima_iglesia_id'])))
                .getSingleOrNull();

        if (savedIglesia != null) {
          super.state = savedIglesia; // Update UI silently
        }
      }
    } catch (e) {
      // Ignore background errors if the user is offline
    }
  }

  // 2. Overwrite the setter to update the cloud automatically
  @override
  set state(Iglesia? value) {
    super.state = value; // Update the local UI instantly

    if (value != null) {
      _updateCloudPreference(value.id);
    }
  }

  Future<void> _updateCloudPreference(String churchId) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Update Supabase in the background quietly
      await supabase
          .from('usuarios_app')
          .update({'ultima_iglesia_id': churchId})
          .eq('id', user.id);
    } catch (e) {
      // Ignore background errors
    }
  }
}

// Replace the old StateProvider with the new StateNotifierProvider
final currentIglesiaProvider =
    StateNotifierProvider<CurrentIglesiaNotifier, Iglesia?>((ref) {
      return CurrentIglesiaNotifier(ref);
    });
