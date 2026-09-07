import 'dart:convert';

import 'package:agrovida_movil/data/terreno_repository.dart';
import 'package:agrovida_movil/data/auth_repository.dart';
import 'package:agrovida_movil/main.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:agrovida_movil/screens/app_shell.dart';
import 'package:agrovida_movil/screens/mapa_page.dart';
import 'package:agrovida_movil/state/terreno_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('muestra la animación inicial antes del login', (tester) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );

    expect(find.byKey(const ValueKey('splash-logo')), findsOneWidget);
    expect(find.text('Bienvenido'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('splash-logo')), findsNothing);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el tablero y permite abrir la lista de terrenos', (
    tester,
  ) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);

    await _completeLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('AgroVida'), findsOneWidget);
    expect(find.text('Resumen de campo'), findsOneWidget);
    expect(find.text('Gestión de parcelas'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);

    await tester.tap(find.text('Terrenos'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay terrenos'), findsOneWidget);
    expect(find.text('Agregar terreno'), findsOneWidget);

    store.dispose();
  });

  testWidgets('respeta las zonas seguras de una pantalla tipo iPhone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);

    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final loginTitlePosition = tester.getTopLeft(find.text('AgroVida'));
    expect(loginTitlePosition.dy, greaterThanOrEqualTo(47));

    await _completeLogin(tester);
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    final titlePosition = tester.getTopLeft(find.text('AgroVida'));

    expect(navigationBar.maintainBottomViewPadding, isTrue);
    expect(titlePosition.dy, greaterThanOrEqualTo(47));
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra y oculta la contraseña del login', (tester) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('valida datos y muestra el error enviado por el servidor', (
    tester,
  ) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(terrenoStore: store, authRepository: _FailedAuthRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingrese su correo electrónico.'), findsOneWidget);
    expect(find.text('Ingrese su contraseña.'), findsOneWidget);

    await _completeLogin(tester);
    await tester.pumpAndSettle();
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Resumen de campo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra la cuenta conectada y permite cerrar sesión', (
    tester,
  ) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await _completeLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sesión conectada'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('juan@gmail.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Sesión conectada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre un terreno de la lista directamente en su ubicación', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);
    await store.crear(
      Terreno(
        nombre: 'Lote norte',
        propietario: 'Responsable',
        latitud: 14.6350,
        longitud: -90.5068,
        creadoEn: DateTime(2026, 9, 6),
        limite: const [
          PuntoBorde(latitud: 14.6352, longitud: -90.5072),
          PuntoBorde(latitud: 14.6351, longitud: -90.5065),
          PuntoBorde(latitud: 14.6345, longitud: -90.5066),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          terrenoStore: store,
          ownsStore: false,
          authenticatedUser: const AuthenticatedUser(
            username: 'juan',
            email: 'juan@gmail.com',
            names: 'Juan',
            lastNames: 'Pérez',
            role: 'Trabajador',
          ),
          onLogout: () {},
          mapTileProviderFactory: _WidgetTestTiles.new,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terrenos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ver en mapa'), findsOneWidget);

    await tester.tap(find.byTooltip('Ver en mapa'));
    await tester.pumpAndSettle();

    final mapPage = tester.widget<MapaPage>(find.byType(MapaPage));
    expect(mapPage.terrenoInicial?.nombre, 'Lote norte');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('Mostrando “Lote norte” en el mapa.'), findsOneWidget);
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    for (final punto in store.terrenos.single.limite) {
      expect(
        camera.visibleBounds.contains(LatLng(punto.latitud, punto.longitud)),
        isTrue,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _completeLogin(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo electrónico'),
    'juan@gmail.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    'MiClave123',
  );
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pump();
}

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  }) async {
    return const LoginResult(
      isSuccess: true,
      data: {
        'user': {
          'username': 'juan',
          'email': 'juan@gmail.com',
          'names': 'Juan',
          'lastNames': 'Pérez',
          'role': 'Trabajador',
        },
      },
    );
  }

  @override
  void dispose() {}
}

class _FailedAuthRepository implements AuthRepository {
  @override
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  }) async {
    return const LoginResult(
      isSuccess: false,
      message: 'Usuario o contraseña incorrectos.',
    );
  }

  @override
  void dispose() {}
}

class _MemoryTerrenoRepository implements TerrenoRepository {
  final List<Terreno> _items = [];
  int _nextId = 1;

  @override
  Future<void> actualizar(Terreno terreno) async {
    final index = _items.indexWhere((item) => item.id == terreno.id);
    _items[index] = terreno;
  }

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final created = terreno.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<void> eliminar(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Terreno>> obtenerTodos() async => List.of(_items);
}

class _WidgetTestTiles extends TileProvider {
  final _image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _image;
}
