import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Added localization import
import 'features/home/screens/home_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
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
    final authStateAsync = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Gestión de Aportes',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,

      // --- ADDED LOCALIZATION DELEGATES FOR SPANISH CALENDARS ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Force Spanish
      ],

      // ---------------------------------------------------------
      home: authStateAsync.when(
        data: (state) {
          final session = state.session;
          if (session != null) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
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
