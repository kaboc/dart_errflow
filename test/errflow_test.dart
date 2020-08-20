import 'package:test/test.dart';

import 'package:errflow/src/errflow.dart';

void main() {
  final errFlow = ErrFlow<int>(100);

  group('function passed to scope()', () {
    test('assert() fails if the function is null', () {
      expect(() => errFlow.scope<void>(null), throwsA(isA<AssertionError>()));
    });

    test('notifier provided by scope() has the default error value', () {
      errFlow.scope<void>((notifier) async {
        notifier.set(200);
      });

      errFlow.scope<void>((notifier) async {
        expect(notifier.lastError, 100);
      });
    });

    test('lastError is updated when set() is called', () {
      errFlow.scope<void>((notifier) async {
        notifier.set(200);
        expect(notifier.lastError, 200);
      });
    });

    test('scope returns the value returned from the passed function', () async {
      final result = await errFlow.scope<int>(
        (_) => Future<int>.value(200),
      );
      expect(result, 200);
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

      await errFlow.scope<String>(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r = true,
      );

      expect(r, isTrue);
    });

    test('onError is called only when errorIf is true', () {
      errFlow.scope<String>(
        (_) => null,
        errorIf: (_, __) => false,
        onError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<String>(
        (_) => null,
        errorIf: (_, __) => true,
        onError: (_, __) => expect(true, isTrue),
      );
    });

    test('errorIf and onError get correct values', () async {
      await errFlow.scope<String>(
        (notifier) => Future<String>.delayed(Duration.zero, () {
          notifier.set(200);
          return 'foo';
        }),
        errorIf: (String result, int error) {
          expect(result, 'foo');
          expect(error, 200);
          return true;
        },
        onError: (String result, int error) {
          expect(result, 'foo');
          expect(error, 200);
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

        await errFlow.scope<String>(
          (_) => null,
          criticalIf: (_, __) => true,
          onCriticalError: (_, __) => r = true,
        );

        expect(r, isTrue);
      },
    );

    test('onCriticalError is called only when criticalIf is true', () {
      errFlow.scope<String>(
        (_) => null,
        criticalIf: (_, __) => false,
        onCriticalError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<String>(
        (_) => null,
        criticalIf: (_, __) => true,
        onCriticalError: (_, __) => expect(true, isTrue),
      );
    });

    test('criticalIf and onCriticalError get correct values', () async {
      errFlow.scope<String>(
        (notifier) => Future<String>.delayed(Duration.zero, () {
          notifier.set(200);
          return 'foo';
        }),
        criticalIf: (String result, int error) {
          expect(result, 'foo');
          expect(error, 200);
          return true;
        },
        onCriticalError: (String result, int error) {
          expect(result, 'foo');
          expect(error, 200);
        },
      );
    });
  });

  group('criticalIf / onCriticalError', () {
    test('onError is ignored if onCriticalError is set', () {
      errFlow.scope<bool>(
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
        (_) => Future<bool>.value(true),
        errorIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('errorHandler is ignored if onError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<bool>(
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
        (_) => Future<bool>.value(true),
        criticalIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('criticalErrorHandler is ignored if onCriticalError is set', () async {
      var r1 = false;
      var r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<bool>(
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
        expect(error, ++i == 1 ? 200 : 300);
      };
      errFlow.addListener(listener);

      await Future.wait([
        errFlow.scope<void>(
          (notifier) async {
            notifier.set(200);
            await Future<void>.delayed(const Duration(milliseconds: 100));
            expect(notifier.lastError, 200);
          },
          onError: (result, error) => expect(error, 200),
        ),
        errFlow.scope<void>(
          (notifier) async {
            notifier.set(300);
            expect(notifier.lastError, 300);
          },
          onError: (result, error) => expect(error, 300),
        ),
      ]);

      errFlow.removeListener(listener);
    });
  });

  group('logger', () {
    test('logger is called with correct values', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope<void>((notifier) async {
        notifier.log('foo', _StackTrace('bar'), 'baz');
        expect(log.exception, 'foo');
        expect(log.stack.toString(), 'bar');
        expect(log.context, 'baz');
      });
    });

    test('logger is called with correct values when context is omitted', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope<void>((notifier) async {
        notifier.log('foo', _StackTrace('bar'));
        expect(log.exception, 'foo');
        expect(log.stack.toString(), 'bar');
        expect(log.context, isNull);
      });
    });

    test('calling set() calls the logger', () {
      final log = _Log();
      errFlow.logger = log.logger;

      errFlow.scope<void>((notifier) async {
        notifier.set(200, 'foo', _StackTrace('bar'), 'baz');
        expect(log.exception, 'foo');
        expect(log.stack.toString(), 'bar');
        expect(log.context, 'baz');
      });
    });

    test('assert() fails if no logger is set but exception is provided', () {
      errFlow.logger = null;

      errFlow.scope<void>((notifier) async {
        expect(
          () => notifier.log(200, _StackTrace('bar')),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    test(
      'assert() fails if log() is called with stack/context but without exception',
      () {
        errFlow.useDefaultLogger();

        errFlow.scope<void>((notifier) async {
          expect(
            () => notifier.log(null, _StackTrace('bar'), 'baz'),
            throwsA(isA<AssertionError>()),
          );
        });
      },
    );
  });

  group('loggingScope() and ignorableScope()', () {
    test('notifier is of LoggingErrNotifier type', () {
      errFlow.loggingScope<void>((notifier) async {
        expect(notifier, isA<LoggingErrNotifier>());
      });
    });

    test('notifier is of IgnorableErrNotifier type', () {
      errFlow.ignorableScope<void>((notifier) async {
        expect(notifier, isA<IgnorableErrNotifier>());
      });
    });
  });
}

class _Log {
  dynamic exception;
  StackTrace stack;
  dynamic context;

  void logger(dynamic e, StackTrace s, {dynamic context}) {
    exception = e;
    stack = s;
    this.context = context;
  }
}

class _StackTrace extends StackTrace {
  _StackTrace(this.value);

  final String value;

  @override
  String toString() => value;
}
