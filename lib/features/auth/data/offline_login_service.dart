import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflineLoginService {
  final _storage = const FlutterSecureStorage();

  static const _keyEmail = 'secure_email';
  static const _keyPassHash = 'secure_pass_hash';

  Future<void> saveCredentials(String email, String password) async {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes).toString();

    await _storage.write(key: _keyEmail, value: email);
    await _storage.write(key: _keyPassHash, value: hash);
  }

  Future<bool> validateOffline(String inputEmail, String inputPassword) async {
    final savedEmail = await _storage.read(key: _keyEmail);
    final savedHash = await _storage.read(key: _keyPassHash);
    if (savedEmail == null || savedHash == null) return false;
    if (savedEmail != inputEmail) return false;

    final inputBytes = utf8.encode(inputPassword);
    final inputHash = sha256.convert(inputBytes).toString();

    return savedHash == inputHash;
  }
}
