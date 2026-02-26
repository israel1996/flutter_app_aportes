import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Riverpod Provider to manage the toggle state
final themeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);

// 2. MODERN DARK THEME (Neon/Cyberpunk)
final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF151521),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF00C9FF), // Neon Cyan
    secondary: Color(0xFFFF4081), // Neon Pink
    surface: Color(0xFF1E1E2C), // Panel color
    onSurface: Colors.white,
  ),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
  cardTheme: CardThemeData(
    color: const Color(0xFF1E1E2C),
    elevation: 8,
    shadowColor: Colors.black.withOpacity(0.4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF2A2A3D),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF00C9FF), width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.white54),
  ),
);

// 3. CLEAN LIGHT THEME (Minimalist/Corporate)
final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF4F5F9),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF3F51B5), // Deep Indigo
    secondary: Color(0xFFE91E63), // Pink
    surface: Colors.white,
    onSurface: Color(0xFF2D3142),
  ),
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.05),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF0F2F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
    ),
    labelStyle: const TextStyle(color: Colors.black54),
  ),
);
