import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _pinKey = 'admin_pin';
  static const String _attemptsKey = 'pin_attempts';

  Future<bool> hasPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  Future<void> setPin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, newPin);
    await resetAttempts();
  }

  Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_attemptsKey) ?? 0;
    return attempts >= 3;
  }

  Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, 0);
  }

  Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();

    if (await isLockedOut()) return false;

    final storedPin = prefs.getString(_pinKey);
    if (storedPin == null) return false;

    if (storedPin == inputPin) {
      await resetAttempts();
      return true;
    } else {
      int currentAttempts = prefs.getInt(_attemptsKey) ?? 0;
      await prefs.setInt(_attemptsKey, currentAttempts + 1);
      return false;
    }
  }
}
