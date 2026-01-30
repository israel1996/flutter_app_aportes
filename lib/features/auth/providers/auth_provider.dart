import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_service.dart';

// 1. Provider for the Service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. Provider for the User State (Listen to changes live)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
