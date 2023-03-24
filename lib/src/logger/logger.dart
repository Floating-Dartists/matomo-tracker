import 'dart:async';
import 'dart:developer' as dev;

import 'package:clock/clock.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';

const _defaultLevel = Level.info;

class Logger {
  Logger([this.name = '']);

  final String name;

  StreamController<LogRecord>? _controller;
  StreamSubscription<LogRecord>? _subscription;

  Level _level = _defaultLevel;
  set level(Level level) => _level = level;

  void finest(Object? message) {
    _publish(
      LogRecord(
        level: Level.finest,
        time: clock.now(),
        message: message,
      ),
    );
  }

  void fine(Object? message) {
    _publish(
      LogRecord(
        level: Level.fine,
        time: clock.now(),
        message: message,
      ),
    );
  }

  void severe({
    Object? message,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _publish(
      LogRecord(
        level: Level.severe,
        time: clock.now(),
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void setLogging({required Level level}) {
    _subscription?.cancel();
    _level = level;
    _subscription = onRecord.listen((record) {
      dev.log(
        record.message.toString(),
        time: record.time,
        level: record.level.value,
        name: name,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  void _publish(LogRecord record) {
    if (record.level.value >= _level.value) {
      _controller?.add(record);
    }
  }

  Stream<LogRecord> get onRecord => _getStream();

  void clearListeners() {
    _controller?.close();
    _controller = null;
  }

  Stream<LogRecord> _getStream() {
    return (_controller ??= StreamController<LogRecord>.broadcast(sync: true))
        .stream;
  }
}
