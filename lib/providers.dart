import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'core/database/database.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

enum AppEnvironment { finanzas, secretaria }

final environmentProvider = StateProvider<AppEnvironment>((ref) {
  return AppEnvironment.finanzas;
});
