import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';
import 'package:matomo_tracker/src/logger/logger.dart';

void main() {
  group('Logger', () {
    final logger = Logger();

    tearDown(logger.clearListeners);

    test('should emit LogRecord if enabled', () {
      final fixedDate = DateTime(2023);

      withClock(
        Clock.fixed(fixedDate),
        () {
          final records = <LogRecord>[];
          final sub = logger.onRecord.listen(records.add);

          logger
            ..setLogging(level: Level.all)
            ..fine('fine')
            ..finest('finest')
            ..severe(message: 'severe');

          sub.cancel();

          expect(
            records,
            [
              LogRecord(
                level: Level.fine,
                time: fixedDate,
                message: 'fine',
              ),
              LogRecord(
                level: Level.finest,
                time: fixedDate,
                message: 'finest',
              ),
              LogRecord(
                level: Level.severe,
                time: fixedDate,
                message: 'severe',
              ),
            ],
          );
        },
      );
    });

    test("shouldn't emit LogRecord if disabled", () {
      final records = <LogRecord>[];
      final sub = logger.onRecord.listen(records.add);

      logger
        ..setLogging(level: Level.off)
        ..fine('fine')
        ..finest('finest')
        ..severe(message: 'severe');

      sub.cancel();

      expect(records, isEmpty);
    });
  });
}
