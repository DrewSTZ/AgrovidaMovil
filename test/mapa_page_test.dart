import 'dart:convert';

import 'package:agrovida_movil/data/terreno_repository.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:agrovida_movil/screens/mapa_page.dart';
import 'package:agrovida_movil/state/terreno_store.dart';
import 'package:agrovida_movil/widgets/lote_editor_panel.dart';
import 'package:agrovida_movil/widgets/mapa_referencias_satelitales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dibuja, deshace, guarda y conserva la identidad visual del lote',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);
      final store = TerrenoStore(MapTestRepository());
      addTearDown(store.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaPage(
              terrenoStore: store,
              tileProviderFactory: MapTestTiles.new,
            ),
            bottomNavigationBar: const SafeArea(
              top: false,
              child: SizedBox(height: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delimitar lote'));
      await tester.pumpAndSettle();
      FilledButton saveButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar lote'),
      );
      LoteEditorPanel panel() =>
          tester.widget<LoteEditorPanel>(find.byType(LoteEditorPanel));
      expect(saveButton().onPressed, isNull);

      for (final point in [
        const Offset(85, 270),
        const Offset(275, 285),
        const Offset(195, 330),
      ]) {
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(panel().puntos, 3);
      expect(panel().hectareas, greaterThan(0));
      expect(panel().perimetroMetros, greaterThan(0));
      expect(saveButton().onPressed, isNotNull);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(panel().puntos, 2);
      expect(saveButton().onPressed, isNull);
      await tester.tapAt(const Offset(195, 330));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Guardar lote'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre de la finca'),
        'Finca El Paraíso',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del terreno'),
        'Lote norte',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Propietario o responsable'),
        'Responsable',
      );
      await tester.tap(find.text('Crear terreno'));
      await tester.pumpAndSettle();
      // Esperar a que el aviso de guardado libere los controles del mapa.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(store.terrenos.single.limite.length, 3);
      expect(find.byType(LoteEditorPanel), findsNothing);

      Color savedColor() => tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons
          .last
          .borderColor;
      final firstColor = savedColor();
      await store.actualizar(
        store.terrenos.single.copyWith(nombre: 'Lote renombrado'),
      );
      await tester.pumpAndSettle();
      expect(savedColor(), firstColor);

      await store.crear(store.terrenos.single.copyWith(nombre: 'Lote sur'));
      await tester.pumpAndSettle();
      final polygons = tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons;
      expect(polygons[1].borderColor, isNot(polygons[3].borderColor));

      await tester.tap(find.text('Delimitar lote'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(100, 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip('Cancelar delimitación'));
      await tester.pumpAndSettle();
      expect(find.byType(LoteEditorPanel), findsNothing);
      expect(store.terrenos.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'alterna satélite con referencias sin perder cámara, dibujo ni proveedores',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.reset);
      final store = TerrenoStore(MapTestRepository());
      addTearDown(store.dispose);
      final providers = <MapTestTiles>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaPage(
              terrenoStore: store,
              tileProviderFactory: () {
                final provider = MapTestTiles();
                providers.add(provider);
                return provider;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(MapaReferenciasSatelitales), findsNothing);
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      final initialCenter = controller.camera.center;
      controller.move(initialCenter, 19);
      await tester.pumpAndSettle();

      for (var cycle = 0; cycle < 3; cycle++) {
        await tester.tap(find.byTooltip('Usar satélite con nombres'));
        await tester.pumpAndSettle();
        final layers = tester.widgetList<TileLayer>(find.byType(TileLayer));
        expect(layers.length, 3);
        expect(layers.first.urlTemplate, contains('World_Imagery'));
        expect(
          layers.elementAt(1).urlTemplate,
          contains('World_Transportation'),
        );
        expect(
          layers.last.urlTemplate,
          contains('World_Boundaries_and_Places'),
        );
        expect(layers.map((layer) => layer.tileProvider).toSet().length, 3);
        expect(layers.every((layer) => layer.maxNativeZoom == 18), isTrue);
        expect(controller.camera.zoom, 18);
        expect(controller.camera.center, initialCenter);
        final children = tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .children;
        expect(
          children.indexWhere((child) => child is MapaReferenciasSatelitales),
          lessThan(children.indexWhere((child) => child is PolygonLayer)),
        );
        final references = providers.sublist(providers.length - 2);
        expect(
          references.every((provider) => provider.requests.isNotEmpty),
          isTrue,
        );
        expect(
          references.every((provider) => provider.disposeCount == 0),
          isTrue,
        );

        if (cycle == 0) {
          await tester.tap(find.text('Delimitar lote'));
          await tester.pumpAndSettle();
          for (final point in [
            const Offset(85, 270),
            const Offset(275, 285),
            const Offset(195, 330),
          ]) {
            await tester.tapAt(point);
            await tester.pump(const Duration(milliseconds: 400));
          }
        }
        expect(
          tester.widget<LoteEditorPanel>(find.byType(LoteEditorPanel)).puntos,
          3,
        );
        await tester.tap(find.byTooltip('Attributions'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Límites y vías: Esri').hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.cancel_outlined));
        await tester.pumpAndSettle();
        // Redibujar el panel no crea nuevas conexiones para las referencias.
        expect(providers.length, 1 + (cycle + 1) * 2);
        await tester.tap(find.byTooltip('Usar mapa estándar'));
        await tester.pumpAndSettle();
        expect(find.byType(TileLayer), findsOneWidget);
        expect(
          tester.widget<TileLayer>(find.byType(TileLayer)).urlTemplate,
          contains('openstreetmap.org'),
        );
        expect(controller.camera.zoom, 18);
        expect(controller.camera.center, initialCenter);
        expect(
          tester.widget<LoteEditorPanel>(find.byType(LoteEditorPanel)).puntos,
          3,
        );
        expect(
          references.every((provider) => provider.disposeCount == 1),
          isTrue,
        );
        expect(providers.first.disposeCount, 0);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(providers.every((provider) => provider.disposeCount == 1), isTrue);
    },
  );
}

/// Mosaicos transparentes: la prueba verifica el dibujo sin red ni caché real.
class MapTestTiles extends TileProvider {
  int disposeCount = 0;
  final requests = <String>[];
  final _image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    assert(disposeCount == 0, 'No se debe reutilizar un proveedor cerrado.');
    requests.add(getTileUrl(coordinates, options));
    return _image;
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }
}

class MapTestRepository implements TerrenoRepository {
  final items = <Terreno>[];
  int _nextId = 1;

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final saved = terreno.copyWith(id: _nextId++);
    items.add(saved);
    return saved;
  }

  @override
  Future<void> actualizar(Terreno terreno) async {
    items[items.indexWhere((item) => item.id == terreno.id)] = terreno;
  }

  @override
  Future<void> eliminar(int id) async =>
      items.removeWhere((item) => item.id == id);

  @override
  Future<List<Terreno>> obtenerTodos() async => List.of(items);
}
