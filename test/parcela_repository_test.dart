import 'dart:convert';

import 'package:agrovida_movil/data/parcela_repository.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('envía la creación de parcela con el contrato acordado', () async {
    late http.Request sentRequest;
    final repository = HttpParcelaRepository(
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Parcela creada',
            'data': {
              'parcela': {'public_id': '79ba5977-e926-47be-aeda-c34c79226053'},
            },
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final terreno = Terreno(
      fincaNombre: 'Finca El Paraíso',
      fincaDescripcion: 'Finca de producción de banano',
      nombre: 'Lote norte',
      descripcion: 'Sector norte',
      propietario: 'Juan Pérez',
      latitud: 14.63505,
      longitud: -90.50675,
      creadoEn: DateTime(2026, 9, 8),
      limite: const [
        PuntoBorde(latitud: 14.6352, longitud: -90.5072),
        PuntoBorde(latitud: 14.6356, longitud: -90.5068),
        PuntoBorde(latitud: 14.6350, longitud: -90.5063),
        PuntoBorde(latitud: 14.6344, longitud: -90.5067),
      ],
    );

    final result = await repository.crear(
      workerPublicId: '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      terreno: terreno,
    );

    expect(result.isSuccess, isTrue);
    expect(result.parcelaPublicId, '79ba5977-e926-47be-aeda-c34c79226053');
    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.toString(),
      'https://breeding-brute-antirust.ngrok-free.dev/'
      'AgroVida/Mobile/MobileParcelas.php',
    );
    expect(sentRequest.headers['content-type'], contains('application/json'));
    expect(jsonDecode(sentRequest.body), {
      'accion': 'crear',
      'trabajador_public_id': '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      'finca': {
        'nombre': 'Finca El Paraíso',
        'propietario': 'Juan Pérez',
        'descripcion': 'Finca de producción de banano',
      },
      'parcela': {
        'nombre': 'Lote norte',
        'descripcion': 'Sector norte',
        'puntos': [
          {'orden': 1, 'latitud': 14.6352, 'longitud': -90.5072},
          {'orden': 2, 'latitud': 14.6356, 'longitud': -90.5068},
          {'orden': 3, 'latitud': 14.6350, 'longitud': -90.5063},
          {'orden': 4, 'latitud': 14.6344, 'longitud': -90.5067},
        ],
      },
    });
  });

  test('no envía una parcela sin identificador del trabajador', () async {
    var requestCount = 0;
    final repository = HttpParcelaRepository(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    final result = await repository.crear(
      workerPublicId: '',
      terreno: Terreno(
        nombre: 'Lote norte',
        propietario: 'Juan Pérez',
        latitud: 14.6352,
        longitud: -90.5072,
        creadoEn: DateTime(2026, 9, 8),
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('iniciar sesión'));
    expect(requestCount, 0);
  });

  test('envía la edición de parcela con el contrato acordado', () async {
    late http.Request sentRequest;
    final repository = HttpParcelaRepository(
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'Parcela actualizada'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final terreno = Terreno(
      id: 8,
      parcelaPublicId: '79ba5977-e926-47be-aeda-c34c79226053',
      nombre: 'Lote norte ampliado',
      descripcion: 'Se modificaron los límites',
      propietario: 'Juan Pérez',
      latitud: 14.6351,
      longitud: -90.5067,
      creadoEn: DateTime(2026, 9, 8),
      limite: const [
        PuntoBorde(latitud: 14.6352, longitud: -90.5072),
        PuntoBorde(latitud: 14.6358, longitud: -90.5067),
        PuntoBorde(latitud: 14.6351, longitud: -90.5061),
        PuntoBorde(latitud: 14.6343, longitud: -90.5068),
      ],
    );

    final result = await repository.editar(
      workerPublicId: '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      parcelaPublicId: terreno.parcelaPublicId,
      terreno: terreno,
    );

    expect(result.isSuccess, isTrue);
    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.toString(),
      'https://breeding-brute-antirust.ngrok-free.dev/'
      'AgroVida/Mobile/MobileParcelas.php',
    );
    expect(sentRequest.headers['content-type'], contains('application/json'));
    expect(jsonDecode(sentRequest.body), {
      'accion': 'editar',
      'trabajador_public_id': '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      'parcela_public_id': '79ba5977-e926-47be-aeda-c34c79226053',
      'parcela': {
        'nombre': 'Lote norte ampliado',
        'descripcion': 'Se modificaron los límites',
        'puntos': [
          {'latitud': 14.6352, 'longitud': -90.5072},
          {'latitud': 14.6358, 'longitud': -90.5067},
          {'latitud': 14.6351, 'longitud': -90.5061},
          {'latitud': 14.6343, 'longitud': -90.5068},
        ],
      },
    });
  });

  test('no edita una parcela sin identificador del servidor', () async {
    var requestCount = 0;
    final repository = HttpParcelaRepository(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    final result = await repository.editar(
      workerPublicId: '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      parcelaPublicId: '',
      terreno: Terreno(
        nombre: 'Lote norte',
        propietario: 'Juan Pérez',
        latitud: 14.6352,
        longitud: -90.5072,
        creadoEn: DateTime(2026, 9, 8),
      ),
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('identificador del servidor'));
    expect(requestCount, 0);
  });

  test('envía la eliminación de parcela con el contrato acordado', () async {
    late http.Request sentRequest;
    final repository = HttpParcelaRepository(
      client: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          jsonEncode({'success': true, 'message': 'Parcela eliminada'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );

    final result = await repository.eliminar(
      workerPublicId: '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      parcelaPublicId: '79ba5977-e926-47be-aeda-c34c79226053',
    );

    expect(result.isSuccess, isTrue);
    expect(sentRequest.method, 'POST');
    expect(
      sentRequest.url.toString(),
      'https://breeding-brute-antirust.ngrok-free.dev/'
      'AgroVida/Mobile/MobileParcelas.php',
    );
    expect(sentRequest.headers['content-type'], contains('application/json'));
    expect(jsonDecode(sentRequest.body), {
      'accion': 'eliminar',
      'trabajador_public_id': '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      'parcela_public_id': '79ba5977-e926-47be-aeda-c34c79226053',
    });
  });

  test('no elimina una parcela sin identificador del servidor', () async {
    var requestCount = 0;
    final repository = HttpParcelaRepository(
      client: MockClient((_) async {
        requestCount++;
        return http.Response('{}', 200);
      }),
    );

    final result = await repository.eliminar(
      workerPublicId: '9b7952be-8a55-4ae1-a609-b3ee2f79e593',
      parcelaPublicId: '',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('identificador del servidor'));
    expect(requestCount, 0);
  });
}
