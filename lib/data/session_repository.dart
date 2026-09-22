import 'auth_repository.dart';

abstract interface class SessionRepository {
  Future<AuthenticatedUser?> read();

  Future<void> save(AuthenticatedUser user);

  Future<void> clear();
}

class TemporarySessionRepository implements SessionRepository {
  AuthenticatedUser? _user;

  @override
  Future<AuthenticatedUser?> read() async => _user;

  @override
  Future<void> save(AuthenticatedUser user) async => _user = user;

  @override
  Future<void> clear() async => _user = null;
}
