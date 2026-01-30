import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Cloud Connection
  await Supabase.initialize(
    url: 'https://khfuugwqxwvzkewuudjl.supabase.co',
    anonKey: 'sb_publishable_iLhG2G-qh2__Ns_xY2H4lA_9H6jzwTN',
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the authentication state live
    final authStateAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Gestión de Diezmos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // LOGIC TO SWITCH SCREENS
      home: authStateAsync.when(
        data: (state) {
          final session = state.session;
          if (session != null) {
            return const HomeScreen(); // Has session -> Go Home
          } else {
            return const LoginScreen(); // No session -> Go Login
          }
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}
