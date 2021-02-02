import 'package:test/test.dart';

import 'package:errflow/src/errflow.dart';

void main() {
  final errFlow = ErrFlow<int>(100);

  group('function passed to scope()', () {
    test('assert() fails if the function is null', () {
      expect(
        () => errFlow.scope<void>(null),
        throwsA(isA<AssertionError>()),
      );
    });

    test('defaultValue has the default value set in constructor', () {
      errFlow.scope<void>((notifier) {
        expect(errFlow.defaultValue, equals(100));
      });
    });

    test('defaultValue does not change even if set() is called', () {
      errFlow.scope<void>((notifier) {
        notifier.set(200);
        expect(errFlow.defaultValue, equals(100));
      });
    });

    test('notifier in scope() has the default value', () async {
      await errFlow.scope<void>((notifier) {
        notifier.set(200);
      });

      errFlow.scope<void>((notifier) {
        expect(notifier.lastError, equals(100));
      });
    });

    test('lastError is updated when set() is called', () {
      errFlow.scope<void>((notifier) {
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
      errFlow.scope<void>((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });
  });

  group('errorIf / onError', () {
    test('assert() fails if both onError and eventHandler are missing', () {
      expect(
        () => errFlow.scope<void>(
          (_) => null,
          errorIf: (_, __) => true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('onError is called even without set() if errorIf is true', () async {
      var r = false;

      await errFlow.scope<void>(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r = true,
      );

      expect(r, isTrue);
    });

    test('onError is called only when errorIf is true', () {
      errFlow.scope<void>(
        (_) => null,
        errorIf: (_, __) => false,
        onError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<void>(
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
        errorIf: (String result, int error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
          return true;
        },
        onError: (String result, int error) {
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
          () => errFlow.scope<void>(
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

        await errFlow.scope<void>(
          (_) => null,
          criticalIf: (_, __) => true,
          onCriticalError: (_, __) => r = true,
        );

        expect(r, isTrue);
      },
    );

    test('onCriticalError is called only when criticalIf is true', () {
      errFlow.scope<void>(
        (_) => null,
        criticalIf: (_, __) => false,
        onCriticalError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<void>(
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
        criticalIf: (String result, int error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
          return true;
        },
        onCriticalError: (String result, int error) {
          expect(result, equals('foo'));
          expect(error, equals(200));
        },
      );
    });
  });

  group('criticalIf / onCriticalError', () {
    test('errorIf is ignored if condition of criticalIf is met', () {
      errFlow.scope<void>(
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
        errorIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('errorHandler is ignored if onError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<void>(
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
        criticalIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('criticalErrorHandler is ignored if onCriticalError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<void>(
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
      final listener =
          ({int error, dynamic exception, StackTrace stack, dynamic context}) {
        expect(error, equals(++i == 1 ? 200 : 300));
      };
      errFlow.addListener(listener);

      await Future.wait([
        errFlow.scope<void>(
          (notifier) async {
            notifier.set(200);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(notifier.lastError, equals(200));
          },
          onError: (result, error) => expect(error, equals(200)),
        ),
        errFlow.scope<void>(
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

      errFlow.scope<void>((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });

    test('logger can return Future but is not awaited', () async {
      final log = _Log();
      errFlow.logger = log.loggerWith100msDelay;

      errFlow.scope<void>((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, isNull);
        expect(log.stack, isNull);
        expect(log.reason, isNull);
      });

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(log.exception, equals('foo'));
      expect(log.stack.toString(), equals('bar'));
      expect(log.reason, equals('baz'));
    });

    test('logger is called with correct values when context is omitted', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope<void>((notifier) {
        notifier.log('foo', _StackTrace('bar'));
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, isNull);
      });
    });

    test('set() calls the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope<void>((notifier) {
        notifier.set(200, 'foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });

    test('assert() fails if no logger is set but exception is provided', () {
      errFlow.logger = null;

      errFlow.scope<void>((notifier) {
        expect(
          () => notifier.log(200, _StackTrace('bar')),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    test(
      'assert() fails on set()/log() with stack/context but without exception',
      () {
        errFlow.useDefaultLogger();

        errFlow.scope<void>((notifier) {
          expect(
            () => notifier.set(200, null, _StackTrace('bar'), 'baz'),
            throwsA(isA<AssertionError>()),
          );
        });

        errFlow.scope<void>((notifier) async {
          expect(
            () => notifier.log(null, _StackTrace('bar'), 'baz'),
            throwsA(isA<AssertionError>()),
          );
        });
      },
    );
  });

  group('loggingScope()', () {
    test('notifier is of LoggingErrNotifier type', () {
      errFlow.loggingScope<void>((notifier) {
        expect(notifier, isA<LoggingErrNotifier>());
      });
    });

    test('notifier has the default value', () async {
      await errFlow.loggingScope<void>((notifier) {
        notifier.set(200);
      });

      errFlow.loggingScope<void>((notifier) {
        expect(notifier.lastError, equals(100));
      });
    });

    test('set() updates last error', () {
      errFlow.loggingScope<void>((notifier) {
        expect(notifier.lastError, equals(100));
        notifier.set(200);
        expect(notifier.lastError, equals(200));
      });
    });

    test('hasError returns an appropriate value', () {
      errFlow.loggingScope<void>((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });

    test('log() calls the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.loggingScope<void>((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, equals('foo'));
        expect(log.stack.toString(), equals('bar'));
        expect(log.reason, equals('baz'));
      });
    });
  });

  group('ignorableScope()', () {
    test('notifier is of IgnorableErrNotifier type', () {
      errFlow.ignorableScope<void>((notifier) {
        expect(notifier, isA<IgnorableErrNotifier>());
      });
    });

    test('notifier has the default value', () async {
      await errFlow.ignorableScope<void>((notifier) {
        notifier.set(200);
      });

      errFlow.ignorableScope<void>((notifier) {
        expect(notifier.lastError, equals(100));
      });
    });

    test('set() updates last error', () {
      errFlow.ignorableScope<void>((notifier) {
        expect(notifier.lastError, equals(100));
        notifier.set(200);
        expect(notifier.lastError, equals(200));
      });
    });

    test('hasError returns an appropriate value', () {
      errFlow.ignorableScope<void>((notifier) {
        expect(notifier.hasError, isFalse);
        notifier.set(200);
        expect(notifier.hasError, isTrue);
      });
    });

    test('log() does not call the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.ignorableScope<void>((notifier) {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, isNull);
        expect(log.stack, isNull);
        expect(log.reason, isNull);
      });
    });
  });

  group('dispose', () {
    final errFlow2 = ErrFlow<int>(100);
    errFlow2.dispose();

    test('cannot be used after disposed', () {
      final listener =
          ({int error, Object exception, StackTrace stack, Object context}) {};
      expect(
        () => errFlow2.addListener(listener),
        throwsA(isA<AssertionError>()),
      );
    });

    test('calling toString() after dispose() causes no error', () {
      expect(
        () => errFlow2.toString(),
        isNot(throwsA(isA<AssertionError>())),
      );
    });
  });
}

class _Log {
  dynamic exception;
  StackTrace stack;
  dynamic reason;

  void logger(dynamic e, StackTrace s, {dynamic reason}) {
    exception = e;
    stack = s;
    this.reason = reason;
  }

  Future<void> loggerWith100msDelay(
    dynamic e,
    StackTrace s, {
    dynamic reason,
  }) async {
    await (() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      exception = e;
      stack = s;
      this.reason = reason;
    })();
  }
}

class _StackTrace extends StackTrace {
  _StackTrace(this.value);

  final String value;

  @override
  String toString() => value;
}
