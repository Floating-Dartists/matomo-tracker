class MatomoException implements Exception {
  const MatomoException({
    required this.message,
  });

  final String message;

  @override
  String toString() => 'MatomoException: $message';
}

class UninitializedMatomoInstanceException extends MatomoException {
  const UninitializedMatomoInstanceException()
      : super(
          message:
              'MatomoTracker has not been initialized properly, call the method initialize() first.',
        );
}

class AlreadyInitializedMatomoInstanceException extends MatomoException {
  const AlreadyInitializedMatomoInstanceException()
      : super(
          message: 'MatomoTracker has already been initialized. '
              'You can check the initialize property to see if it has been initialized.',
        );
}
