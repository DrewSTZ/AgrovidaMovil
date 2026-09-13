import 'package:agrovida_movil/models/terreno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conserva los puntos del borde al convertir un terreno en mapa', () {
    final terreno = Terreno(
      parcelaPublicId: '79ba5977-e926-47be-aeda-c34c79226053',
      fincaNombre: 'Finca El Paraíso',
      fincaDescripcion: 'Producción de banano',
      nombre: 'Lote Norte',
      descripcion: 'Sector norte',
      propietario: 'Andree',
      latitud: 14.6349,
      longitud: -90.5069,
      creadoEn: DateTime(2026, 9, 1),
      limite: const [
        PuntoBorde(latitud: 14.6349, longitud: -90.5069),
        PuntoBorde(latitud: 14.6351, longitud: -90.5067),
        PuntoBorde(latitud: 14.6347, longitud: -90.5065),
      ],
    );

    final restaurado = Terreno.fromMap(terreno.toMap());

    expect(restaurado.tieneLimite, isTrue);
    expect(restaurado.parcelaPublicId, '79ba5977-e926-47be-aeda-c34c79226053');
    expect(restaurado.fincaNombre, 'Finca El Paraíso');
    expect(restaurado.fincaDescripcion, 'Producción de banano');
    expect(restaurado.descripcion, 'Sector norte');
    expect(restaurado.limite, hasLength(3));
    expect(restaurado.limite[1].longitud, closeTo(-90.5067, 0.000001));
  });
}
