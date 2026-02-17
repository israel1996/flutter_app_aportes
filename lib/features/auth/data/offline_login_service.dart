import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineLoginService {
  final _storage = const FlutterSecureStorage();

  static const _keyEmail = 'secure_email';
  static const _keyPassword = 'secure_password';

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<bool> validateOffline(String inputEmail, String inputPassword) async {
    final savedEmail = await _storage.read(key: _keyEmail);
    final savedPassword = await _storage.read(key: _keyPassword);

    if (savedEmail == null || savedPassword == null) return false;

    return savedEmail == inputEmail && savedPassword == inputPassword;
  }

  Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _keyEmail);
    final password = await _storage.read(key: _keyPassword);

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
