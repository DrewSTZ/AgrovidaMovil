import 'package:agrovida_movil/services/image_quality_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = ImageQualityAnalyzer();

  test('rechaza una imagen oscura y sin contraste', () {
    final result = analyzer.analyzeLuminance(
      luminance: List.filled(100, 20),
      width: 10,
      height: 10,
    );

    expect(result.isAcceptable, isFalse);
    expect(result.issues, contains(ImageQualityIssue.tooDark));
    expect(result.issues, contains(ImageQualityIssue.lowContrast));
  });

  test('rechaza una imagen sobreexpuesta', () {
    final result = analyzer.analyzeLuminance(
      luminance: List.filled(100, 245),
      width: 10,
      height: 10,
    );

    expect(result.isAcceptable, isFalse);
    expect(result.issues, contains(ImageQualityIssue.tooBright));
  });

  test('rechaza una imagen uniforme como borrosa', () {
    final result = analyzer.analyzeLuminance(
      luminance: List.filled(100, 125),
      width: 10,
      height: 10,
    );

    expect(result.isAcceptable, isFalse);
    expect(result.issues, contains(ImageQualityIssue.blurry));
  });

  test('acepta una imagen con luz, contraste y bordes definidos', () {
    final pixels = <double>[];
    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        pixels.add((x + y).isEven ? 70 : 190);
      }
    }

    final result = analyzer.analyzeLuminance(
      luminance: pixels,
      width: 20,
      height: 20,
      originalWidth: 1200,
      originalHeight: 1600,
    );

    expect(result.isAcceptable, isTrue);
    expect(result.issues, isEmpty);
  });

  test('rechaza una fotografía con resolución insuficiente', () {
    final pixels = <double>[];
    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        pixels.add((x + y).isEven ? 70 : 190);
      }
    }

    final result = analyzer.analyzeLuminance(
      luminance: pixels,
      width: 20,
      height: 20,
      originalWidth: 320,
      originalHeight: 480,
    );

    expect(result.isAcceptable, isFalse);
    expect(result.issues, contains(ImageQualityIssue.tooSmall));
  });

  test('rechaza una fotografía con encuadre extremadamente alargado', () {
    final pixels = <double>[];
    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        pixels.add((x + y).isEven ? 70 : 190);
      }
    }

    final result = analyzer.analyzeLuminance(
      luminance: pixels,
      width: 20,
      height: 20,
      originalWidth: 600,
      originalHeight: 2400,
    );

    expect(result.isAcceptable, isFalse);
    expect(result.issues, contains(ImageQualityIssue.extremeAspectRatio));
  });

  test('rechaza datos de imagen incompletos', () {
    expect(
      () => analyzer.analyzeLuminance(
        luminance: const [10, 20, 30],
        width: 3,
        height: 3,
      ),
      throwsFormatException,
    );
  });
}
