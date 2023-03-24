import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/logger/log_record.dart';

void main() {
  group('LogRecord', () {
    group('hashCode', () {
      test('should be equal for equal objects', () {
        final time = DateTime(2023);
        final stackTrace = StackTrace.fromString('stackTrace');

        final record1 = LogRecord(
          level: Level.fine,
          time: time,
          message: 'message',
          error: 'error',
          stackTrace: stackTrace,
        );

        final record2 = LogRecord(
          level: Level.fine,
          time: time,
          message: 'message',
          error: 'error',
          stackTrace: stackTrace,
        );

        expect(record1.hashCode, record2.hashCode);
      });
    });
  });
}
