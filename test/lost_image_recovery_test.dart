import 'package:agrovida_movil/services/lost_image_recovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('recupera la fotografía que Android devolvió después del reinicio', () async {
    final result = await const LostImageRecovery().recover(
      _RecoveredImagePicker(XFile('foto_recuperada.jpg')),
    );

    expect(result.image?.path, 'foto_recuperada.jpg');
    expect(result.errorMessage, isNull);
  });

  test('no muestra error cuando Android no tiene datos perdidos', () async {
    final result = await const LostImageRecovery().recover(
      _EmptyImagePicker(),
    );

    expect(result.isEmpty, isTrue);
  });
}

class _RecoveredImagePicker extends ImagePicker {
  _RecoveredImagePicker(this.file);

  final XFile file;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    return LostDataResponse(files: [file], type: RetrieveType.image);
  }
}

class _EmptyImagePicker extends ImagePicker {
  @override
  Future<LostDataResponse> retrieveLostData() async {
    return LostDataResponse.empty();
  }
}
