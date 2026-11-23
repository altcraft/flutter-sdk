/// Exception thrown by the Altcraft SDK.
class AltcraftException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const AltcraftException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AltcraftException($code): $message';
}

/// Thrown when SDK operations are called before initialization.
class SdkNotInitializedException extends AltcraftException {
  const SdkNotInitializedException()
      : super(
            code: 'SDK_NOT_INITIALIZED',
            message: 'SDK has not been initialized');
}
