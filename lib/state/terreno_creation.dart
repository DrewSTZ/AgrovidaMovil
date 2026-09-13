import '../models/terreno.dart';

class TerrenoCreationResult {
  const TerrenoCreationResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

typedef TerrenoCreator =
    Future<TerrenoCreationResult> Function(Terreno terreno);

class TerrenoUpdateResult {
  const TerrenoUpdateResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

typedef TerrenoUpdater = Future<TerrenoUpdateResult> Function(Terreno terreno);

class TerrenoDeletionResult {
  const TerrenoDeletionResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

typedef TerrenoDeleter =
    Future<TerrenoDeletionResult> Function(Terreno terreno);
