import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class LostImageRecoveryResult {
  const LostImageRecoveryResult({this.image, this.errorMessage});

  final XFile? image;
  final String? errorMessage;

  bool get isEmpty => image == null && errorMessage == null;
}

class LostImageRecovery {
  const LostImageRecovery();

  Future<LostImageRecoveryResult> recover(ImagePicker picker) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const LostImageRecoveryResult();
    }

    try {
      final response = await picker.retrieveLostData();
      if (response.isEmpty) return const LostImageRecoveryResult();
      final files = response.files;
      if (files != null && files.isNotEmpty) {
        return LostImageRecoveryResult(image: files.first);
      }
      return const LostImageRecoveryResult(
        errorMessage:
            'Android no pudo recuperar la fotografía anterior. Selecciona una nueva.',
      );
    } on MissingPluginException {
      return const LostImageRecoveryResult();
    } on UnimplementedError {
      return const LostImageRecoveryResult();
    } catch (_) {
      return const LostImageRecoveryResult(
        errorMessage:
            'No se pudo recuperar la fotografía anterior. Selecciona una nueva.',
      );
    }
  }
}
