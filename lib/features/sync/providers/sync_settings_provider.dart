import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final autoSyncEnabledProvider = StateNotifierProvider<AutoSyncNotifier, bool>((
  ref,
) {
  return AutoSyncNotifier();
});

class AutoSyncNotifier extends StateNotifier<bool> {
  AutoSyncNotifier() : super(true) {
    _loadPreference();
  }

  static const _key = 'auto_sync_enabled';

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    state = value;
  }
}
