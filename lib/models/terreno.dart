import 'dart:convert';

class PuntoBorde {
  const PuntoBorde({required this.latitud, required this.longitud});

  final double latitud;
  final double longitud;

  Map<String, double> toMap() => {'latitud': latitud, 'longitud': longitud};

  factory PuntoBorde.fromMap(Map<String, Object?> map) {
    return PuntoBorde(
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
    );
  }
}

class Terreno {
  const Terreno({
    this.id,
    this.parcelaPublicId = '',
    required this.nombre,
    required this.propietario,
    this.fincaNombre = '',
    this.fincaDescripcion = '',
    this.descripcion = '',
    required this.latitud,
    required this.longitud,
    required this.creadoEn,
    this.limite = const [],
  });

  final int? id;
  final String parcelaPublicId;
  final String nombre;
  final String propietario;
  final String fincaNombre;
  final String fincaDescripcion;
  final String descripcion;
  final double latitud;
  final double longitud;
  final DateTime creadoEn;
  final List<PuntoBorde> limite;

  bool get tieneLimite => limite.length >= 3;

  Terreno copyWith({
    int? id,
    String? parcelaPublicId,
    String? nombre,
    String? propietario,
    String? fincaNombre,
    String? fincaDescripcion,
    String? descripcion,
    double? latitud,
    double? longitud,
    DateTime? creadoEn,
    List<PuntoBorde>? limite,
  }) {
    return Terreno(
      id: id ?? this.id,
      parcelaPublicId: parcelaPublicId ?? this.parcelaPublicId,
      nombre: nombre ?? this.nombre,
      propietario: propietario ?? this.propietario,
      fincaNombre: fincaNombre ?? this.fincaNombre,
      fincaDescripcion: fincaDescripcion ?? this.fincaDescripcion,
      descripcion: descripcion ?? this.descripcion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      creadoEn: creadoEn ?? this.creadoEn,
      limite: limite ?? this.limite,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'parcela_public_id': parcelaPublicId,
      'nombre': nombre,
      'propietario': propietario,
      'finca_nombre': fincaNombre,
      'finca_descripcion': fincaDescripcion,
      'descripcion': descripcion,
      'latitud': latitud,
      'longitud': longitud,
      'creado_en': creadoEn.toIso8601String(),
      'limite_json': jsonEncode(limite.map((punto) => punto.toMap()).toList()),
    };
  }

  factory Terreno.fromMap(Map<String, Object?> map) {
    return Terreno(
      id: map['id'] as int?,
      parcelaPublicId: map['parcela_public_id'] as String? ?? '',
      nombre: map['nombre'] as String,
      propietario: map['propietario'] as String,
      fincaNombre: map['finca_nombre'] as String? ?? '',
      fincaDescripcion: map['finca_descripcion'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      latitud: (map['latitud'] as num).toDouble(),
      longitud: (map['longitud'] as num).toDouble(),
      creadoEn: DateTime.parse(map['creado_en'] as String),
      limite: _limiteDesdeJson(map['limite_json']),
    );
  }

  static List<PuntoBorde> _limiteDesdeJson(Object? rawJson) {
    if (rawJson is! String || rawJson.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map>()
          .map((punto) => PuntoBorde.fromMap(Map<String, Object?>.from(punto)))
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}
