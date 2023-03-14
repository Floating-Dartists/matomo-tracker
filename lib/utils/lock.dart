import 'dart:async';

/// Simple lock implementation to prevent concurrent access to asynchronous
/// code.
///
/// Based on tekartik's [basic_lock.dart](https://github.com/tekartik/synchronized.dart/blob/master/synchronized/lib/src/basic_lock.dart)
class Lock {
  Future<dynamic>? last;

  bool get locked => last != null;

  Future<T> synchronized<T>(
    FutureOr<T> Function() func,
  ) async {
    final prev = last;
    final completer = Completer<void>.sync();
    last = completer.future;
    try {
      if (prev != null) {
        await prev;
      }

      final result = func();
      return result;
    } finally {
      if (identical(last, completer.future)) {
        last = null;
      }
      completer.complete();
    }
  }
}
