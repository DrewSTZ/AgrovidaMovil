import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_quality_analyzer.dart';
import '../services/lost_image_recovery.dart';

class DiagnosticoPage extends StatefulWidget {
  const DiagnosticoPage({
    super.key,
    this.imagePicker,
    this.qualityAnalyzer = const ImageQualityAnalyzer(),
    this.lostImageRecovery = const LostImageRecovery(),
  });

  final ImagePicker? imagePicker;
  final ImageQualityAnalyzer qualityAnalyzer;
  final LostImageRecovery lostImageRecovery;

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  late final ImagePicker _imagePicker;
  XFile? _selectedImage;
  ImageQualityResult? _qualityResult;
  bool _isAnalyzing = false;
  bool _wasRecovered = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.imagePicker ?? ImagePicker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverLostImage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Diagnóstico de banano',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Toma una fotografía clara de la hoja. AgroVida revisará su calidad antes del análisis.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedImage == null) ...[
            _CaptureCard(
              onCamera: () => _pickAndAnalyze(ImageSource.camera),
              onGallery: () => _pickAndAnalyze(ImageSource.gallery),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              _ErrorCard(message: _errorMessage!),
            ],
            const SizedBox(height: 20),
            const _PhotoGuide(),
          ] else ...[
            _ImagePreview(
              image: _selectedImage!,
              isAnalyzing: _isAnalyzing,
            ),
            const SizedBox(height: 14),
            if (_wasRecovered) ...[
              const _RecoveredPhotoNotice(),
              const SizedBox(height: 12),
            ],
            if (_errorMessage != null)
              _ErrorCard(message: _errorMessage!)
            else if (_qualityResult != null)
              _QualityResultCard(result: _qualityResult!),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Otra foto'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _PrivacyNotice(),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 1920,
      );
      if (image == null || !mounted) return;
      await _analyzeImage(image);
    } on PlatformException catch (error) {
      if (!mounted) return;
      final permissionDenied = error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      setState(() {
        _isAnalyzing = false;
        _errorMessage = permissionDenied
            ? 'AgroVida necesita permiso para acceder a la cámara o a tus fotografías. Puedes habilitarlo desde los ajustes del teléfono.'
            : 'No se pudo abrir la fotografía. Inténtalo nuevamente.';
      });
    } on FileSystemException {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'La fotografía ya no está disponible. Selecciona otra imagen.';
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'El archivo seleccionado no es una fotografía válida. Intenta con otra imagen.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'No se pudo revisar la fotografía. Inténtalo nuevamente.';
      });
    }
  }

  Future<void> _recoverLostImage() async {
    final recovered = await widget.lostImageRecovery.recover(_imagePicker);
    if (!mounted || recovered.isEmpty) return;
    if (recovered.image != null) {
      try {
        await _analyzeImage(recovered.image!, wasRecovered: true);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isAnalyzing = false;
          _errorMessage =
              'La fotografía recuperada no es válida. Puedes tomar una nueva.';
        });
      }
    } else {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = recovered.errorMessage;
      });
    }
  }

  Future<void> _analyzeImage(
    XFile image, {
    bool wasRecovered = false,
  }) async {
    setState(() {
      _selectedImage = image;
      _qualityResult = null;
      _errorMessage = null;
      _isAnalyzing = true;
      _wasRecovered = wasRecovered;
    });

    final bytes = await image.readAsBytes();
    final result = await widget.qualityAnalyzer.analyze(bytes);
    if (!mounted) return;
    setState(() {
      _qualityResult = result;
      _isAnalyzing = false;
    });
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fotografía una hoja',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Primero comprobaremos que tenga buena luz, nitidez y contraste.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('diagnosis-camera-button'),
              onPressed: onCamera,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.primary,
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Tomar fotografía'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('diagnosis-gallery-button'),
            onPressed: onGallery,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir de la galería'),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image, required this.isAnalyzing});

  final XFile image;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(image.path), fit: BoxFit.cover),
            if (isAnalyzing) ...[
              const ColoredBox(color: Color(0x8F000000)),
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 14),
                    Text(
                      'Revisando la fotografía…',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QualityResultCard extends StatelessWidget {
  const _QualityResultCard({required this.result});

  final ImageQualityResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accepted = result.isAcceptable;
    final tone = accepted ? colors.primary : colors.error;
    final background = accepted
        ? colors.primaryContainer.withValues(alpha: 0.55)
        : colors.errorContainer.withValues(alpha: 0.65);

    return Container(
      key: const ValueKey('diagnosis-quality-result'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                accepted
                    ? Icons.check_circle_rounded
                    : Icons.photo_camera_back_outlined,
                color: tone,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accepted
                          ? 'Foto lista para el diagnóstico'
                          : 'Necesitamos otra fotografía',
                      style: TextStyle(
                        color: tone,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accepted
                          ? 'La imagen tiene calidad suficiente. El reconocimiento de enfermedades se incorporará con el modelo de la semana 8.'
                          : _recommendation(result.issues),
                      style: TextStyle(
                        color: accepted
                            ? colors.onPrimaryContainer
                            : colors.onErrorContainer,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QualityChip(
                label: 'Iluminación',
                isValid: result.hasGoodLighting,
              ),
              _QualityChip(label: 'Nitidez', isValid: result.isSharp),
              _QualityChip(
                label: 'Contraste',
                isValid: result.hasEnoughContrast,
              ),
              _QualityChip(
                label: 'Encuadre',
                isValid: result.hasUsableFraming,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _recommendation(Set<ImageQualityIssue> issues) {
    final recommendations = <String>[];
    if (issues.contains(ImageQualityIssue.tooDark)) {
      recommendations.add('busca un lugar con más luz');
    }
    if (issues.contains(ImageQualityIssue.tooBright)) {
      recommendations.add('evita el sol directo o el flash');
    }
    if (issues.contains(ImageQualityIssue.blurry)) {
      recommendations.add('mantén el teléfono firme y enfoca la hoja');
    }
    if (issues.contains(ImageQualityIssue.lowContrast)) {
      recommendations.add('acércate y usa un fondo que se distinga de la hoja');
    }
    if (issues.contains(ImageQualityIssue.tooSmall)) {
      recommendations.add('usa una imagen de mayor resolución');
    }
    if (issues.contains(ImageQualityIssue.extremeAspectRatio)) {
      recommendations.add('encuadra la hoja completa en una foto normal');
    }
    return '${recommendations.join(', ')}.';
  }
}

class _RecoveredPhotoNotice extends StatelessWidget {
  const _RecoveredPhotoNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.restore_rounded, color: colors.onSecondaryContainer),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Recuperamos la fotografía que Android había interrumpido.',
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  const _QualityChip({required this.label, required this.isValid});

  final String label;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isValid ? colors.primary : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_rounded : Icons.close_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PhotoGuide extends StatelessWidget {
  const _PhotoGuide();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cómo tomar una buena foto',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const _GuideItem(
              icon: Icons.light_mode_outlined,
              text: 'Usa luz natural, sin sombras fuertes ni reflejos.',
            ),
            const _GuideItem(
              icon: Icons.center_focus_strong_outlined,
              text: 'Enfoca la hoja completa y mantén el teléfono firme.',
            ),
            const _GuideItem(
              icon: Icons.zoom_in_map_outlined,
              text: 'Acércate lo suficiente para que el daño sea visible.',
            ),
            const SizedBox(height: 4),
            const _PrivacyNotice(),
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.phonelink_lock_outlined, color: color, size: 19),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'La revisión de calidad se realiza en el teléfono; esta pantalla no envía la foto al servidor.',
            style: TextStyle(color: color, fontSize: 12.5, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
