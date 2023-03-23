import 'package:flutter/foundation.dart';

@immutable
class LogRecord {
  const LogRecord({
    required this.level,
    this.time,
    this.message,
    this.error,
    this.stackTrace,
  });

  final Level level;
  final DateTime? time;
  final Object? message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LogRecord &&
            runtimeType == other.runtimeType &&
            level == other.level &&
            time == other.time &&
            message == other.message &&
            error == other.error &&
            stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    return Object.hash(level, time, message, error, stackTrace);
  }
}

enum Level {
  finest(300),
  fine(500),
  severe(1000);

  const Level(this.value);

  final int value;
}
