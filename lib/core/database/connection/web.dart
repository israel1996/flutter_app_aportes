import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

LazyDatabase connect() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'db_iglesia',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );

    if (result.missingFeatures.isNotEmpty) {
      // Handle browsers that don't support file system access nicely
      debugPrint('Using IndexedDB fallback');
      return result.resolvedExecutor;
    }
    return result.resolvedExecutor;
  });
}
