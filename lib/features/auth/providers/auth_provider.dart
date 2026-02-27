import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final userRoleProvider = FutureProvider.autoDispose<String>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) return 'usuario';

  try {
    final data = await supabase
        .from('usuarios_app')
        .select('rol')
        .eq('id', user.id)
        .single();
    return data['rol'] as String;
  } catch (e) {
    return 'usuario';
  }
});
