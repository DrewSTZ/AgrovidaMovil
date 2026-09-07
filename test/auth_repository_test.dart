import 'dart:convert';

import 'package:agrovida_movil/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía exactamente usuario y contrasena como JSON', () async {
    late http.Request sentRequest;
    final repository = HttpAuthRepository(
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'mensaje': 'Bienvenido'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.login(
      usuario: 'juan@gmail.com',
      contrasena: 'MiClave123',
    );

    expect(result.isSuccess, isTrue);
    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.toString(),
      'https://breeding-brute-antirust.ngrok-free.dev/'
      'AgroVida/Mobile/MobileLogin.php',
    );
    expect(sentRequest.headers['content-type'], contains('application/json'));
    expect(jsonDecode(sentRequest.body), {
      'usuario': 'juan@gmail.com',
      'contrasena': 'MiClave123',
    });
  });

  test('respeta un rechazo JSON aunque el servidor responda 200', () async {
    final repository = HttpAuthRepository(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'mensaje': 'Credenciales inválidas'}),
          200,
        ),
      ),
    );

    final result = await repository.login(
      usuario: 'juan@gmail.com',
      contrasena: 'incorrecta',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Credenciales inválidas');
  });

  test('muestra un mensaje entendible cuando HTTP rechaza el acceso', () async {
    final repository = HttpAuthRepository(
      client: MockClient((_) async => http.Response('', 401)),
    );

    final result = await repository.login(
      usuario: 'juan@gmail.com',
      contrasena: 'incorrecta',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Usuario o contraseña incorrectos.');
  });

  test('no acepta una respuesta 200 que contiene un error', () async {
    final repository = HttpAuthRepository(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'error': 'Usuario no existe'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

    final result = await repository.login(
      usuario: 'desconocido@gmail.com',
      contrasena: 'MiClave123',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Usuario no existe');
  });
}
