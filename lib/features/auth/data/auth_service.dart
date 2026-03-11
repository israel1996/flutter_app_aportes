import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    // Ya no verificamos el estado aquí, el LoginScreen lo hará antes de llamar a esta función.
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signUp(String email, String password, String nombre) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user != null) {
      await _supabase.from('usuarios_app').insert({
        'id': user.id,
        'email': email,
        'nombre': nombre,
        'rol': 'usuario',
        'estado': 'pendiente',
      });
    }
    await _supabase.auth.signOut();
  }
}
