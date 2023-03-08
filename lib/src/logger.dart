import 'dart:developer' as dev;

class Logger {
  Logger([this.name = '']);

  final String name;

  void finest(Object? message) => log(Level.finest, message);
  void fine(Object? message) => log(Level.fine, message);

  void log(Level level, Object? message) {
    dev.log(
      message.toString(),
      time: DateTime.now(),
      level: level.value,
      name: name,
    );
  }
}

enum Level {
  finest(300),
  fine(500);

  const Level(this.value);

  final int value;
}
