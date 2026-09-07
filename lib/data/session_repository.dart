import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_repository.dart';

abstract interface class SessionRepository {
  Future<AuthenticatedUser?> read();

  Future<void> save(AuthenticatedUser user);

  Future<void> clear();
}

class SecureSessionRepository implements SessionRepository {
  SecureSessionRepository({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'agrovida_authenticated_user';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthenticatedUser?> read() async {
    try {
      final storedValue = await _storage.read(key: _sessionKey);
      if (storedValue == null || storedValue.isEmpty) return null;

      final decoded = jsonDecode(storedValue);
      if (decoded is! Map) {
        await clear();
        return null;
      }

      final user = AuthenticatedUser.fromStoredData(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (user.accountIdentifier.isEmpty) {
        await clear();
        return null;
      }
      return user;
    } on FormatException {
      await clear();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(AuthenticatedUser user) {
    return _storage.write(
      key: _sessionKey,
      value: jsonEncode(user.toStoredData()),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}
