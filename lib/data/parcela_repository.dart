import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/terreno.dart';

class ParcelaResult {
  const ParcelaResult({
    required this.isSuccess,
    this.message,
    this.data = const {},
    this.parcelaPublicId = '',
  });

  final bool isSuccess;
  final String? message;
  final Map<String, Object?> data;
  final String parcelaPublicId;
}

abstract interface class ParcelaRepository {
  Future<ParcelaResult> crear({
    required String workerPublicId,
    required Terreno terreno,
  });

  Future<ParcelaResult> editar({
    required String workerPublicId,
    required String parcelaPublicId,
    required Terreno terreno,
  });

  Future<ParcelaResult> eliminar({
    required String workerPublicId,
    required String parcelaPublicId,
  });

  void dispose();
}

class HttpParcelaRepository implements ParcelaRepository {
  HttpParcelaRepository({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final Duration timeout;

  @override
  Future<ParcelaResult> crear({
    required String workerPublicId,
    required Terreno terreno,
  }) async {
    if (workerPublicId.trim().isEmpty) {
      return const ParcelaResult(
        isSuccess: false,
        message: 'Vuelve a iniciar sesión para registrar la parcela.',
      );
    }

    return _post(
      _crearPayload(workerPublicId, terreno),
      successMessage: 'Parcela registrada correctamente.',
      failureMessage:
          'El servidor no pudo registrar la parcela. Inténtalo nuevamente.',
      timeoutMessage: 'El servidor tardó demasiado en registrar la parcela.',
    );
  }

  @override
  Future<ParcelaResult> editar({
    required String workerPublicId,
    required String parcelaPublicId,
    required Terreno terreno,
  }) {
    if (workerPublicId.trim().isEmpty) {
      return Future.value(
        const ParcelaResult(
          isSuccess: false,
          message: 'Vuelve a iniciar sesión para editar la parcela.',
        ),
      );
    }
    if (parcelaPublicId.trim().isEmpty) {
      return Future.value(
        const ParcelaResult(
          isSuccess: false,
          message:
              'Esta parcela no tiene el identificador del servidor y no se puede editar todavía.',
        ),
      );
    }

    return _post(
      _editarPayload(workerPublicId, parcelaPublicId, terreno),
      successMessage: 'Parcela actualizada correctamente.',
      failureMessage:
          'El servidor no pudo actualizar la parcela. Inténtalo nuevamente.',
      timeoutMessage: 'El servidor tardó demasiado en actualizar la parcela.',
    );
  }

  @override
  Future<ParcelaResult> eliminar({
    required String workerPublicId,
    required String parcelaPublicId,
  }) {
    if (workerPublicId.trim().isEmpty) {
      return Future.value(
        const ParcelaResult(
          isSuccess: false,
          message: 'Vuelve a iniciar sesión para eliminar la parcela.',
        ),
      );
    }
    if (parcelaPublicId.trim().isEmpty) {
      return Future.value(
        const ParcelaResult(
          isSuccess: false,
          message:
              'Esta parcela no tiene el identificador del servidor y no se puede eliminar todavía.',
        ),
      );
    }

    return _post(
      {
        'accion': 'eliminar',
        'trabajador_public_id': workerPublicId.trim(),
        'parcela_public_id': parcelaPublicId.trim(),
      },
      successMessage: 'Parcela eliminada correctamente.',
      failureMessage:
          'El servidor no pudo eliminar la parcela. Inténtalo nuevamente.',
      timeoutMessage: 'El servidor tardó demasiado en eliminar la parcela.',
    );
  }

  Future<ParcelaResult> _post(
    Map<String, Object?> payload, {
    required String successMessage,
    required String failureMessage,
    required String timeoutMessage,
  }) async {
    try {
      final response = await _client
          .post(
            ApiConfig.parcelasUrl,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=UTF-8',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);

      final body = _decodeBody(response.bodyBytes).trim();
      final data = _decodeObject(body);
      final message = _messageFrom(data, body);
      final statusIsSuccess =
          response.statusCode >= 200 && response.statusCode < 300;
      final backendSuccess = _backendSuccess(data);

      if (statusIsSuccess && backendSuccess != false && !_looksLikeHtml(body)) {
        return ParcelaResult(
          isSuccess: true,
          message: message ?? successMessage,
          data: data,
          parcelaPublicId: _parcelaPublicIdFrom(data),
        );
      }

      return ParcelaResult(
        isSuccess: false,
        message: message ?? failureMessage,
        data: data,
        parcelaPublicId: _parcelaPublicIdFrom(data),
      );
    } on TimeoutException {
      return ParcelaResult(isSuccess: false, message: timeoutMessage);
    } on SocketException {
      return const ParcelaResult(
        isSuccess: false,
        message: 'No hay conexión con el servidor.',
      );
    } on http.ClientException {
      return const ParcelaResult(
        isSuccess: false,
        message: 'No se pudo conectar con el servidor.',
      );
    } on FormatException {
      return const ParcelaResult(
        isSuccess: false,
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  String _parcelaPublicIdFrom(Map<String, Object?> data) {
    String read(Map<Object?, Object?> source, List<String> keys) {
      for (final key in keys) {
        final value = source[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final direct = read(data, const ['parcela_public_id', 'parcelaPublicId']);
    if (direct.isNotEmpty) return direct;

    for (final containerKey in const ['parcela', 'data', 'resultado']) {
      final rawContainer = data[containerKey];
      if (rawContainer is! Map) continue;
      final nested = read(rawContainer, const [
        'parcela_public_id',
        'parcelaPublicId',
        'public_id',
        'publicId',
      ]);
      if (nested.isNotEmpty) return nested;

      final rawParcela = rawContainer['parcela'];
      if (rawParcela is Map) {
        final nestedParcela = read(rawParcela, const [
          'parcela_public_id',
          'parcelaPublicId',
          'public_id',
          'publicId',
        ]);
        if (nestedParcela.isNotEmpty) return nestedParcela;
      }
    }
    return '';
  }

  Map<String, Object?> _crearPayload(String workerPublicId, Terreno terreno) {
    final puntos = terreno.limite.isNotEmpty
        ? terreno.limite
        : [PuntoBorde(latitud: terreno.latitud, longitud: terreno.longitud)];

    return {
      'accion': 'crear',
      'trabajador_public_id': workerPublicId.trim(),
      'finca': {
        'nombre': terreno.fincaNombre,
        'propietario': terreno.propietario,
        'descripcion': terreno.fincaDescripcion,
      },
      'parcela': {
        'nombre': terreno.nombre,
        'descripcion': terreno.descripcion,
        'puntos': [
          for (var index = 0; index < puntos.length; index++)
            {
              'orden': index + 1,
              'latitud': puntos[index].latitud,
              'longitud': puntos[index].longitud,
            },
        ],
      },
    };
  }

  Map<String, Object?> _editarPayload(
    String workerPublicId,
    String parcelaPublicId,
    Terreno terreno,
  ) {
    final puntos = terreno.limite.isNotEmpty
        ? terreno.limite
        : [PuntoBorde(latitud: terreno.latitud, longitud: terreno.longitud)];

    return {
      'accion': 'editar',
      'trabajador_public_id': workerPublicId.trim(),
      'parcela_public_id': parcelaPublicId.trim(),
      'parcela': {
        'nombre': terreno.nombre,
        'descripcion': terreno.descripcion,
        'puntos': [
          for (final punto in puntos)
            {'latitud': punto.latitud, 'longitud': punto.longitud},
        ],
      },
    };
  }

  Map<String, Object?> _decodeObject(String body) {
    if (body.isEmpty || _looksLikeHtml(body)) return const {};
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return const {};
      return Map<String, Object?>.from(decoded);
    } on FormatException {
      return const {};
    }
  }

  String _decodeBody(List<int> bytes) {
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

    for (final key in const ['success', 'ok']) {
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
