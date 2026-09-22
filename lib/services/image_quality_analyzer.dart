import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

enum ImageQualityIssue {
  tooDark,
  tooBright,
  blurry,
  lowContrast,
  tooSmall,
  extremeAspectRatio,
}

class ImageQualityResult {
  const ImageQualityResult({
    required this.issues,
    required this.averageLuminance,
    required this.contrast,
    required this.laplacianVariance,
    required this.width,
    required this.height,
  });

  final Set<ImageQualityIssue> issues;
  final double averageLuminance;
  final double contrast;
  final double laplacianVariance;
  final int width;
  final int height;

  bool get isAcceptable => issues.isEmpty;

  bool get hasGoodLighting =>
      !issues.contains(ImageQualityIssue.tooDark) &&
      !issues.contains(ImageQualityIssue.tooBright);

  bool get isSharp => !issues.contains(ImageQualityIssue.blurry);

  bool get hasEnoughContrast =>
      !issues.contains(ImageQualityIssue.lowContrast);

  bool get hasUsableFraming =>
      !issues.contains(ImageQualityIssue.tooSmall) &&
      !issues.contains(ImageQualityIssue.extremeAspectRatio);
}

class ImageQualityAnalyzer {
  const ImageQualityAnalyzer();

  static const _analysisWidth = 512;
  static const _darkLuminanceLimit = 52.0;
  static const _brightLuminanceLimit = 230.0;
  static const _minimumContrast = 18.0;
  static const _minimumLaplacianVariance = 90.0;
  static const _minimumShortSide = 480;
  static const _maximumAspectRatio = 3.0;

  Future<ImageQualityResult> analyze(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final targetWidth = math.min(_analysisWidth, descriptor.width).toInt();
      codec = await descriptor.instantiateCodec(targetWidth: targetWidth);
      final frame = await codec.getNextFrame();
      image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) {
        throw const FormatException('No se pudo leer la imagen seleccionada.');
      }

      final luminance = Float64List(image.width * image.height);
      var pixelIndex = 0;
      for (var offset = 0; offset < rgba.lengthInBytes; offset += 4) {
        final red = rgba.getUint8(offset);
        final green = rgba.getUint8(offset + 1);
        final blue = rgba.getUint8(offset + 2);
        luminance[pixelIndex++] =
            (0.2126 * red) + (0.7152 * green) + (0.0722 * blue);
      }

      return analyzeLuminance(
        luminance: luminance,
        width: image.width,
        height: image.height,
        originalWidth: descriptor.width,
        originalHeight: descriptor.height,
      );
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }

  @visibleForTesting
  ImageQualityResult analyzeLuminance({
    required List<double> luminance,
    required int width,
    required int height,
    int? originalWidth,
    int? originalHeight,
  }) {
    if (width < 3 || height < 3 || luminance.length != width * height) {
      throw const FormatException('Los datos de la imagen no son válidos.');
    }

    var sum = 0.0;
    var darkPixels = 0;
    var brightPixels = 0;
    for (final value in luminance) {
      sum += value;
      if (value < 45) darkPixels++;
      if (value > 235) brightPixels++;
    }

    final average = sum / luminance.length;
    var squaredDifferenceSum = 0.0;
    for (final value in luminance) {
      final difference = value - average;
      squaredDifferenceSum += difference * difference;
    }
    final contrastVariance = (squaredDifferenceSum / luminance.length)
        .clamp(0, double.infinity)
        .toDouble();
    final contrastDeviation = math.sqrt(contrastVariance);

    var laplacianSum = 0.0;
    var laplacianSquaredSum = 0.0;
    var laplacianCount = 0;
    for (var y = 1; y < height - 1; y++) {
      final row = y * width;
      for (var x = 1; x < width - 1; x++) {
        final index = row + x;
        final laplacian =
            (4 * luminance[index]) -
            luminance[index - 1] -
            luminance[index + 1] -
            luminance[index - width] -
            luminance[index + width];
        laplacianSum += laplacian;
        laplacianSquaredSum += laplacian * laplacian;
        laplacianCount++;
      }
    }

    final laplacianAverage = laplacianSum / laplacianCount;
    final laplacianVariance =
        (laplacianSquaredSum / laplacianCount) -
        (laplacianAverage * laplacianAverage);

    final darkRatio = darkPixels / luminance.length;
    final brightRatio = brightPixels / luminance.length;
    final sourceWidth = originalWidth ?? width;
    final sourceHeight = originalHeight ?? height;
    final shortSide = math.min(sourceWidth, sourceHeight);
    final longSide = math.max(sourceWidth, sourceHeight);
    final aspectRatio = longSide / shortSide;
    final issues = <ImageQualityIssue>{};
    if (average < _darkLuminanceLimit || darkRatio > 0.62) {
      issues.add(ImageQualityIssue.tooDark);
    }
    if (average > _brightLuminanceLimit || brightRatio > 0.65) {
      issues.add(ImageQualityIssue.tooBright);
    }
    if (contrastDeviation < _minimumContrast) {
      issues.add(ImageQualityIssue.lowContrast);
    }
    if (laplacianVariance < _minimumLaplacianVariance) {
      issues.add(ImageQualityIssue.blurry);
    }
    if (shortSide < _minimumShortSide) {
      issues.add(ImageQualityIssue.tooSmall);
    }
    if (aspectRatio > _maximumAspectRatio) {
      issues.add(ImageQualityIssue.extremeAspectRatio);
    }

    return ImageQualityResult(
      issues: Set.unmodifiable(issues),
      averageLuminance: average,
      contrast: contrastDeviation,
      laplacianVariance: laplacianVariance,
      width: sourceWidth,
      height: sourceHeight,
    );
  }
}
