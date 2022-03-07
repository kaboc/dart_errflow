// ignore_for_file: cascade_invocations

import 'package:test/test.dart';

import 'package:errflow/src/errflow.dart';

void main() {
  final errFlow = ErrFlow<int>(100);

  group('function passed to scope()', () {
    test('defaultValue has the default value set in constructor', () {
      errFlow.scope((notifier) {
        expect(errFlow.defaultValue, equals(100));
      });
    });

    test('defaultValue can be null', () {
      final errFlow2 = ErrFlow<int>();
      errFlow.scope((notifier) {
        expect(errFlow2.defaultValue, isNull);
      });
    });

    test('defaultValue does not change even if set() is called', () {
      errFlow.scope((notifier) {
        notifier.set(200);
        expect(errFlow.defaultValue, equals(100));
      });
    });

    test('notifier has the default value', () async {
      await errFlow.scope((notifier) {
        notifier.set(200);
      });

      await errFlow.scope((notifier) {
        expect(notifier.lastError, equals(100));
      });

      final errFlow2 = ErrFlow<int>();
      await errFlow2.scope((notifier) {
        notifier.set(200);
      });

      await errFlow2.scope((notifier) {
        expect(notifier.lastError, isNull);
      });
    });

    test('lastError is updated when set() is called', () {
      errFlow.scope((notifier) {
        notifier.set(200);
        expect(notifier.lastError, equals(200));
      });
    });

    test(
      'function passed to scope() can return either Future or non-Future',
      () async {
        final result = await errFlow.scope<int>(
          (_) => Future<int>.value(200),
        );
        expect(result, equals(200));

        final result2 = await errFlow.scope<int>(
          (_) => 300,
        );
        expect(result2, equals(300));
      },
    );

    test('hasError returns an appropriate value', () {
      errFlow.scope((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });

      final errFlow2 = ErrFlow<int>();
      errFlow2.scope((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });
  });

  group('errorIf / onError', () {
    test('assert() fails if both onError and eventHandler are missing', () {
      expect(
        () => errFlow.scope(
          (_) => null,
          errorIf: (_, __) => true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('onError is called even without set() if errorIf is true', () async {
      var r = false;

      await errFlow.scope(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r = true,
      );

      expect(r, isTrue);
    });

    test('onError is called only when errorIf is true', () {
      errFlow.scope(
        (_) => null,
        errorIf: (_, __) => false,
        onError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => expect(true, isTrue),
      );
    });

    test('errorIf and onError get correct values', () {
      errFlow.scope<String>(
        (notifier) {
          notifier.set(200);
          return 'foo';
        },
        errorIf: (result, error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
          return true;
        },
        onError: (result, error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
        },
      );
    });
  });

  group('criticalIf / onCriticalError', () {
    test(
      'assert() fails if onCriticalError and criticalErrorHandler are missing',
      () {
        expect(
          () => errFlow.scope(
            (_) => null,
            criticalIf: (_, __) => true,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'onCriticalError is called even without set() if criticalErrorIf is true',
      () async {
        var r = false;

        await errFlow.scope(
          (_) => null,
          criticalIf: (_, __) => true,
          onCriticalError: (_, __) => r = true,
        );

        expect(r, isTrue);
      },
    );

    test('onCriticalError is called only when criticalIf is true', () {
      errFlow.scope(
        (_) => null,
        criticalIf: (_, __) => false,
        onCriticalError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope(
        (_) => null,
        criticalIf: (_, __) => true,
        onCriticalError: (_, __) => expect(true, isTrue),
      );
    });

    test('criticalIf and onCriticalError get correct values', () {
      errFlow.scope<String>(
        (notifier) {
          notifier.set(200);
          return 'foo';
        },
        criticalIf: (result, error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
          return true;
        },
        onCriticalError: (result, error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
        },
      );
    });
  });

  group('criticalIf / onCriticalError', () {
    test('errorIf is ignored if condition of criticalIf is met', () {
      errFlow.scope(
        (_) => null,
        errorIf: (_, __) => true,
        criticalIf: (_, __) => true,
        onError: (_, __) => expect(false, isTrue),
        onCriticalError: (_, __) => expect(true, isTrue),
      );
    });
  });

  group('default handlers', () {
    test('errorHandler is used if set', () async {
      var r = false;

      errFlow.errorHandler = <bool>(bool result, _) {
        r = result == true; // Writing `r = result;` shows a strange error...
      };

      await errFlow.scope<bool>(
        (_) => true,
        errorIf: (result, _) => result,
      );

      expect(r, isTrue);
    });

    test('errorHandler is ignored if onError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r2 = true,
      );

      expect(r1, isFalse);
      expect(r2, isTrue);
    });

    test('criticalErrorHandler is used if set', () async {
      var r = false;

      errFlow.criticalErrorHandler = <bool>(bool result, _) {
        r = result == true; // Writing `r = result;` shows a strange error...
      };

      await errFlow.scope<bool>(
        (_) => true,
        criticalIf: (result, _) => result,
      );

      expect(r, isTrue);
    });

    test('criticalErrorHandler is ignored if onCriticalError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope(
        (_) => null,
        criticalIf: (_, __) => true,
        onCriticalError: (_, __) => r2 = true,
      );

      expect(r1, isFalse);
      expect(r2, isTrue);
    });
  });

  group('concurrency', () {
    test('error in a scope does not affect another concurrent scope', () async {
      var i = 0;
      void listener({
        int? error,
        Object? exception,
        StackTrace? stack,
        Object? context,
      }) {
        expect(error, equals(++i == 1 ? 200 : 300));
      }

      errFlow.addListener(listener);

      await Future.wait([
        errFlow.scope(
          (notifier) async {
            notifier.set(200);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(notifier.lastError, equals(200));
          },
          onError: (result, error) => expect(error, equals(200)),
        ),
        errFlow.scope(
          (notifier) {
            notifier.set(300);
            expect(notifier.lastError, equals(300));
          },
          onError: (result, error) => expect(error, equals(300)),
        ),
      ]);

      errFlow.removeListener(listener);
    });
  });

  group('logger', () {
    test('logger is called with correct values', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });

    test('logger can return Future but is not awaited', () async {
      final log = _Log();

      await errFlow.scope((notifier) {
        errFlow.logger = log.loggerWith100msDelay;
        notifier.log('foo1', _StackTrace('bar1'), 'baz1');

        errFlow.logger = log.logger;
        notifier.log('foo2', _StackTrace('bar2'), 'baz2');

        expect(log.exception, equals('foo2'));
        expect(log.stack.toString(), equals('bar2'));
        expect(log.reason, equals('baz2'));
      });

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(log.exception, equals('foo1'));
      expect(log.stack.toString(), equals('bar1'));
      expect(log.reason, equals('baz1'));
    });

    test('logger is called with correct values when context is omitted', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope((notifier) {
        notifier.log('foo', _StackTrace('bar'));
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, isNull);
      });
    });

    test('set() calls the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope((notifier) {
        notifier.set(200, 'foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });

    test('assert() fails if no logger is set but exception is provided', () {
      errFlow.logger = null;

      errFlow.scope((notifier) {
        expect(
          () => notifier.log(200, _StackTrace('bar')),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    test(
      'assert() fails on set() with stack/context but without exception',
      () {
        errFlow.useDefaultLogger();

        errFlow.scope((notifier) {
          expect(
            () => notifier.set(200, null, _StackTrace('bar'), 'baz'),
            throwsA(isA<AssertionError>()),
          );
        });
      },
    );
  });

  group('loggingScope()', () {
    test('notifier is of type LoggingErrNotifier', () {
      errFlow.loggingScope((notifier) {
        expect(notifier, isA<LoggingErrNotifier>());
      });
    });

    test('notifier has the default value', () async {
      await errFlow.loggingScope((notifier) {
        notifier.set(200);
      });

      await errFlow.loggingScope((notifier) {
        expect(notifier.lastError, equals(100));
      });
    });

    test('set() updates last error', () {
      errFlow.loggingScope((notifier) {
        expect(notifier.lastError, equals(100));
        notifier.set(200);
        expect(notifier.lastError, equals(200));
      });
    });

    test('hasError returns an appropriate value', () {
      errFlow.loggingScope((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });

    test('log() calls the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.loggingScope((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });
  });

  group('ignorableScope()', () {
    test('notifier is of type IgnorableErrNotifier', () {
      errFlow.ignorableScope((notifier) {
        expect(notifier, isA<IgnorableErrNotifier>());
      });
    });

    test('notifier has the default value', () async {
      await errFlow.ignorableScope((notifier) {
        notifier.set(200);
      });

      await errFlow.ignorableScope((notifier) {
        expect(notifier.lastError, equals(100));
      });
    });

    test('set() updates last error', () {
      errFlow.ignorableScope((notifier) {
        expect(notifier.lastError, equals(100));
        notifier.set(200);
        expect(notifier.lastError, equals(200));
      });
    });

    test('hasError returns an appropriate value', () {
      errFlow.ignorableScope((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });

    test('log() does not call the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.ignorableScope((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(() => log.exception, throwsA(isA<Error>()));
        expect(log.stack, isNull);
        expect(log.reason, isNull);
      });
    });
  });

  group('combiningScope()', () {
    test('notifier is of type LoggingErrNotifier', () {
      errFlow.combiningScope((notifier) {
        expect(notifier, isA<LoggingErrNotifier>());
      });
    });

    test('Result has default error value if there was no error', () async {
      final result = await errFlow.combiningScope((_) => 'abc');
      expect(result.value, equals('abc'));
      expect(result.error, equals(100));
    });

    test(
      'error is null if there was no error and default error is null',
      () async {
        final errFlow2 = ErrFlow<int>();
        final result = await errFlow2.combiningScope((_) => 'abc');
        expect(result.value, equals('abc'));
        expect(result.error, isNull);
      },
    );

    test('hasError is false if there was no error', () async {
      final result = await errFlow.combiningScope((_) => 'abc');
      expect(result.hasError, isFalse);
    });

    test(
      'hasError is false if there was no error and default error is null',
      () async {
        final errFlow2 = ErrFlow<int>();
        final result = await errFlow2.combiningScope((_) => 'abc');
        expect(result.hasError, isFalse);
      },
    );

    test('hasError is true if there was an error', () async {
      final result = await errFlow.combiningScope<String>((notifier) {
        notifier.set(200);
        return '';
      });
      expect(result.hasError, isTrue);
    });

    test('Result has both value and error if there was an error', () async {
      final result = await errFlow.combiningScope<String>((notifier) {
        notifier.set(300);
        return 'def';
      });
      expect(result.value, 'def');
      expect(result.error, 300);
    });
  });

  group('dispose', () {
    late ErrFlow<int> errFlow2;

    setUp(() => errFlow2 = ErrFlow<int>(100));

    test('cannot be used after disposed', () {
      errFlow2.dispose();
      expect(() => errFlow2.scope((_) {}), throwsA(isA<StateError>()));
    });

    test('calling toString() after dispose() causes no error', () {
      errFlow2.dispose();
      expect(errFlow2.toString, isNot(throwsA(anything)));
    });

    test('calling dispose() in scope does not stop notifier in the scope', () {
      final log = _Log();
      errFlow2.logger = log.logger;

      errFlow2.scope((notifier) {
        errFlow2.dispose();

        // dispose() above is not applied to the notifier here because
        // this is a copy of the notifier held globally in ErrFlow.
        // Only the global one has been disposed and this instance is not.
        notifier.log('foo');
        expect(log.exception, equals('foo'));
      });

      expect(() => errFlow2.scope((_) {}), throwsA(isA<StateError>()));
    });
  });
}

class _Log {
  late Object exception;
  StackTrace? stack;
  Object? reason;

  void logger(Object e, StackTrace? s, {Object? reason}) {
    exception = e;
    stack = s;
    this.reason = reason;
  }

  Future<void> loggerWith100msDelay(
    Object e,
    StackTrace? s, {
    Object? reason,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100), () {
      exception = e;
      stack = s;
      this.reason = reason;
    });
  }
}

class _StackTrace extends StackTrace {
  _StackTrace(this.value);

  final String value;

  @override
  String toString() => value;
}
