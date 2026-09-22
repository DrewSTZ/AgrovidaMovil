import 'package:agrovida_movil/screens/diagnostico_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('presenta captura, galería y guía de calidad', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DiagnosticoPage())),
    );

    expect(find.text('Diagnóstico de banano'), findsOneWidget);
    expect(find.text('Fotografía una hoja'), findsOneWidget);
    expect(find.text('Tomar fotografía'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(find.text('Cómo tomar una buena foto'), findsOneWidget);
    expect(find.text('Módulo en preparación'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
