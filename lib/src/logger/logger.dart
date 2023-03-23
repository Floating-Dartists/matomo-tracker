import 'dart:async';
import 'dart:developer' as dev;

import 'package:clock/clock.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';

class Logger {
  Logger([this.name = '']);

  final String name;

  StreamController<LogRecord>? _controller;
  StreamSubscription<LogRecord>? _subscription;

  void finest(Object? message) {
    _controller?.add(
      LogRecord(
        level: Level.finest,
        time: clock.now(),
        message: message,
      ),
    );
  }

  void fine(Object? message) {
    _controller?.add(
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
    _controller?.add(
      LogRecord(
        level: Level.severe,
        time: clock.now(),
        message: message,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  void setLogging({required bool enabled}) {
    _subscription?.cancel();
    if (!enabled) {
      clearListeners();
      return;
    }

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
