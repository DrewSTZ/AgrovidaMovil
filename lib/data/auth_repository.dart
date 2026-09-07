import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class LoginResult {
  const LoginResult({
    required this.isSuccess,
    this.message,
    this.data = const {},
  });

  final bool isSuccess;
  final String? message;
  final Map<String, Object?> data;
}

class AuthenticatedUser {
  const AuthenticatedUser({
    this.publicId = '',
    required this.username,
    required this.email,
    required this.names,
    required this.lastNames,
    required this.role,
  });

  final String publicId;
  final String username;
  final String email;
  final String names;
  final String lastNames;
  final String role;

  factory AuthenticatedUser.fromLoginData(
    Map<String, Object?> data, {
    required String fallbackIdentifier,
  }) {
    final rawUser = data['user'];
    final user = rawUser is Map
        ? rawUser.map((key, value) => MapEntry(key.toString(), value))
        : const <String, Object?>{};

    String read(String key) => user[key]?.toString().trim() ?? '';

    final username = read('username');
    final email = read('email');
    return AuthenticatedUser(
      publicId: read('publicId'),
      username: username.isNotEmpty ? username : fallbackIdentifier,
      email: email.isNotEmpty
          ? email
          : (fallbackIdentifier.contains('@') ? fallbackIdentifier : ''),
      names: read('names'),
      lastNames: read('lastNames'),
      role: read('role'),
    );
  }

  factory AuthenticatedUser.fromStoredData(Map<String, Object?> data) {
    String read(String key) => data[key]?.toString().trim() ?? '';

    return AuthenticatedUser(
      publicId: read('publicId'),
      username: read('username'),
      email: read('email'),
      names: read('names'),
      lastNames: read('lastNames'),
      role: read('role'),
    );
  }

  Map<String, Object?> toStoredData() => {
    'publicId': publicId,
    'username': username,
    'email': email,
    'names': names,
    'lastNames': lastNames,
    'role': role,
  };

  String get displayName {
    final fullName = [
      names,
      lastNames,
    ].where((part) => part.isNotEmpty).join(' ');
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    return email;
  }

  String get accountIdentifier => email.isNotEmpty ? email : username;

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

abstract interface class AuthRepository {
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  });

  void dispose();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  @override
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  }) async {
    try {
      final response = await _client
          .post(
            ApiConfig.loginUrl,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              // Evita la página informativa de ngrok en solicitudes de API.
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'usuario': usuario, 'contrasena': contrasena}),
          )
          .timeout(timeout);

      final body = _decodeBody(response.bodyBytes).trim();
      final data = _decodeObject(body);
      final message = _messageFrom(data, body);
      final statusIsSuccess =
          response.statusCode >= 200 && response.statusCode < 300;
      final backendSuccess = _backendSuccess(data);

      if (statusIsSuccess && backendSuccess != false && !_looksLikeHtml(body)) {
        return LoginResult(isSuccess: true, message: message, data: data);
      }

      return LoginResult(
        isSuccess: false,
        message:
            message ??
            (response.statusCode == 401 || response.statusCode == 403
                ? 'Usuario o contraseña incorrectos.'
                : 'No se pudo iniciar sesión. Inténtalo nuevamente.'),
        data: data,
      );
    } on TimeoutException {
      return const LoginResult(
        isSuccess: false,
        message: 'El servidor tardó demasiado en responder.',
      );
    } on SocketException {
      return const LoginResult(
        isSuccess: false,
        message: 'No hay conexión con el servidor.',
      );
    } on http.ClientException {
      return const LoginResult(
        isSuccess: false,
        message: 'No se pudo conectar con el servidor.',
      );
    } on FormatException {
      return const LoginResult(
        isSuccess: false,
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  Map<String, Object?> _decodeObject(String body) {
    if (body.isEmpty || _looksLikeHtml(body)) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return const {};
      return Map<String, Object?>.from(decoded);
    } on FormatException {
      // Algunos servicios PHP devuelven un mensaje de texto en vez de JSON.
      return const {};
    }
  }

  String _decodeBody(List<int> bytes) {
    // JSON usa UTF-8. El respaldo Latin-1 tolera respuestas PHP sin charset.
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  bool? _backendSuccess(Map<String, Object?> data) {
    final error = data['error'];
    if (error != null && error != false && error.toString().trim().isNotEmpty) {
      return false;
    }

    for (final key in const ['success', 'ok', 'autenticado', 'authenticated']) {
      final value = data[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.toLowerCase().trim();
        if (const [
          'true',
          'ok',
          'success',
          'exito',
          'éxito',
        ].contains(normalized)) {
          return true;
        }
        if (const ['false', 'error', 'failed', 'fallo'].contains(normalized)) {
          return false;
        }
      }
    }

    final status = (data['status'] ?? data['estado'])
        ?.toString()
        .toLowerCase()
        .trim();
    if (status != null) {
      if (const ['ok', 'success', 'exito', 'éxito'].contains(status)) {
        return true;
      }
      if (const ['error', 'failed', 'fallo'].contains(status)) return false;
    }

    final message = _messageFrom(data, '');
    if (message != null) {
      final normalized = message.toLowerCase();
      if (const [
        'incorrect',
        'invál',
        'invalid',
        'deneg',
        'no existe',
        'error',
        'falló',
      ].any(normalized.contains)) {
        return false;
      }
    }
    return null;
  }

  String? _messageFrom(Map<String, Object?> data, String rawBody) {
    for (final key in const [
      'mensaje',
      'message',
      'error',
      'detalle',
      'detail',
    ]) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    if (data.isEmpty && rawBody.isNotEmpty && !_looksLikeHtml(rawBody)) {
      return rawBody.length <= 180 ? rawBody : null;
    }
    return null;
  }

  bool _looksLikeHtml(String value) {
    final normalized = value.toLowerCase();
    return normalized.startsWith('<!doctype html') ||
        normalized.startsWith('<html');
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
