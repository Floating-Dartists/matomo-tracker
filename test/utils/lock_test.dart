import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/utils/lock.dart';

void main() {
  group('Lock', () {
    test('should stay locked until the async task completes', () async {
      final lock = Lock();
      var running = 0;
      var maxRunning = 0;

      Future<void> task() => lock.synchronized(() async {
            running++;
            if (running > maxRunning) maxRunning = running;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            running--;
          });

      final first = task();
      expect(lock.locked, isTrue);
      await Future.wait([first, task(), task()]);

      expect(maxRunning, 1);
      expect(lock.locked, isFalse);
    });
  });
}
