import 'dart:convert';

import 'package:agrovida_movil/data/auth_repository.dart';
import 'package:agrovida_movil/data/session_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'guarda, restaura y elimina la sesión sin almacenar contraseña',
    () async {
      const storage = FlutterSecureStorage();
      final repository = SecureSessionRepository(storage: storage);
      const user = AuthenticatedUser(
        publicId: 'usuario-publico-1',
        workerPublicId: 'trabajador-publico-1',
        username: 'juan',
        email: 'juan@gmail.com',
        names: 'Juan',
        lastNames: 'Pérez',
        role: 'Trabajador',
      );

      await repository.save(user);
      final restored = await repository.read();

      expect(restored?.publicId, user.publicId);
      expect(restored?.workerPublicId, user.workerPublicId);
      expect(restored?.email, user.email);
      expect(restored?.displayName, 'Juan Pérez');

      final storedValues = await storage.readAll();
      final storedJson = jsonDecode(storedValues.values.single) as Map;
      expect(storedJson.containsKey('contrasena'), isFalse);
      expect(storedJson.containsKey('password'), isFalse);

      await repository.clear();
      expect(await repository.read(), isNull);
    },
  );
}
