import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

LazyDatabase connect() {
  return LazyDatabase(() async {
    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'aportes_database.sqlite');

    return NativeDatabase.createInBackground(File(dbPath));
  });
}
