import 'dart:developer' as dev;

class Logger {
  Logger([this.name = '']);

  final String name;

  void finest(Object? message) => log(Level.finest, message);

  void fine(Object? message) => log(Level.fine, message);

  void severe({
    Object? message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      Level.severe,
      message,
      stackTrace: stackTrace,
      error: error,
    );
  }

  void log(
    Level level,
    Object? message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      message.toString(),
      time: DateTime.now(),
      level: level.value,
      name: name,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

enum Level {
  finest(300),
  fine(500),
  severe(1000);

  const Level(this.value);

  final int value;
}
