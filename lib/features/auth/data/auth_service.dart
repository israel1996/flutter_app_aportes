import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user != null) {
      try {
        final userData = await _supabase
            .from('usuarios_app')
            .select('estado, rol')
            .eq('id', user.id)
            .single();

        final estado = userData['estado'];

        if (estado == 'pendiente') {
          await signOut();
          throw Exception(
            'Su cuenta está pendiente de aprobación por el administrador.',
          );
        } else if (estado == 'inactivo') {
          await signOut();
          throw Exception(
            'Su cuenta ha sido desactivada. Contacte al administrador.',
          );
        } else if (estado == 'solicita_reseteo') {
          await signOut();
          throw Exception(
            'Has solicitado un cambio de clave. Espera a que el administrador te asigne la clave temporal.',
          );
        }
      } catch (e) {
        if (e.toString().contains('Su cuenta')) {
          rethrow;
        } else {
          await signOut();
          throw Exception(
            'Error verificando la cuenta. Es posible que no esté registrado correctamente.',
          );
        }
      }
    }

    return response;
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
