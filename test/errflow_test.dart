import 'package:test/test.dart';

import 'package:errflow/errflow.dart';

void main() {
  final ErrFlow<int> errFlow = ErrFlow<int>(100);

  group('lastError', () {
    test('default error is set to lastError on initialisation', () {
      expect(errFlow.lastError, 100);
    });

    test('lastError is updated when set() is called', () {
      errFlow.set(200);
      expect(errFlow.lastError, 200);
    });
  });

  group('function passed to scope()', () {
    test('assert() fails if the function is null', () {
      expect(() => errFlow.scope<void>(null), throwsA(isA<AssertionError>()));
    });

    test('error is reset to default when the function is called', () {
      errFlow.set(200);

      errFlow.scope<void>(() {
        expect(errFlow.lastError, 100);
        return null;
      });
    });

    test('scope returns the value returned from the passed function', () async {
      final int result = await errFlow.scope<int>(
        () => Future<int>.value(200),
      );
      expect(result, 200);
    });
  });

  group('errorIf / onError', () {
    test('assert() fails if both onError and eventHandler are missing', () {
      expect(
        () => errFlow.scope<void>(
          () => null,
          errorIf: (_, __) => true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('onError is called even without set() if errorIf is true', () async {
      bool r = false;

      await errFlow.scope<String>(
        () => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r = true,
      );

      expect(r, isTrue);
    });

    test('onError is called only when errorIf is true', () {
      errFlow.scope<String>(
        () => null,
        errorIf: (_, __) => false,
        onError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<String>(
        () => null,
        errorIf: (_, __) => true,
        onError: (_, __) => expect(true, isTrue),
      );
    });

    test('errorIf and onError get correct values', () async {
      await errFlow.scope<String>(
        () => Future<String>.delayed(Duration.zero, () {
          errFlow.set(200);
          return 'foo';
        }),
        errorIf: (String result, int value) {
          expect(result, 'foo');
          expect(value, 200);
          return true;
        },
        onError: (String result, int value) {
          expect(result, 'foo');
          expect(value, 200);
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
            () => null,
            criticalIf: (_, __) => true,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test(
      'onCriticalError is called even without set() if criticalErrorIf is true',
      () async {
        bool r = false;

        await errFlow.scope<String>(
          () => null,
          criticalIf: (_, __) => true,
          onCriticalError: (_, __) => r = true,
        );

        expect(r, isTrue);
      },
    );

    test('onCriticalError is called only when criticalIf is true', () {
      errFlow.scope<String>(
        () => null,
        criticalIf: (_, __) => false,
        onCriticalError: (_, __) => expect(false, isTrue),
      );

      errFlow.scope<String>(
        () => null,
        criticalIf: (_, __) => true,
        onCriticalError: (_, __) => expect(true, isTrue),
      );
    });

    test('criticalIf and onCriticalError get correct values', () async {
      errFlow.scope<String>(
        () => Future<String>.delayed(Duration.zero, () {
          errFlow.set(200);
          return 'foo';
        }),
        criticalIf: (String result, int value) {
          expect(result, 'foo');
          expect(value, 200);
          return true;
        },
        onCriticalError: (String result, int value) {
          expect(result, 'foo');
          expect(value, 200);
        },
      );
    });
  });

  group('criticalIf / onCriticalError', () {
    test('onError is ignored if onCriticalError is set', () {
      errFlow.scope<bool>(
        () => null,
        errorIf: (_, __) => true,
        criticalIf: (_, __) => true,
        onError: (_, __) => expect(false, isTrue),
        onCriticalError: (_, __) => expect(true, isTrue),
      );
    });
  });

  group('default handlers', () {
    test('errorHandler is used if set', () async {
      final ErrFlow<int> errFlow = ErrFlow<int>(0);
      bool r = false;

      errFlow.errorHandler = <bool>(bool result, _) {
        r = result == true; // Writing `r = result;` shows a strange error...
      };

      await errFlow.scope<bool>(
        () => Future<bool>.value(true),
        errorIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('errorHandler is ignored if onError is set', () async {
      final ErrFlow<int> errFlow = ErrFlow<int>(0);
      bool r1 = false;
      bool r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<bool>(
        () => null,
        errorIf: (_, __) => true,
        onError: (_, __) => r2 = true,
      );

      expect(r1, isFalse);
      expect(r2, isTrue);
    });

    test('criticalErrorHandler is used if set', () async {
      final ErrFlow<int> errFlow = ErrFlow<int>(0);
      bool r = false;

      errFlow.criticalErrorHandler = <bool>(bool result, _) {
        r = result == true; // Writing `r = result;` shows a strange error...
      };

      await errFlow.scope<bool>(
        () => Future<bool>.value(true),
        criticalIf: (bool result, _) => result,
      );

      expect(r, isTrue);
    });

    test('criticalErrorHandler is ignored if onCriticalError is set', () async {
      final ErrFlow<int> errFlow = ErrFlow<int>(0);
      bool r1 = false;
      bool r2 = false;

      errFlow.errorHandler = <bool>(_, __) => r1 = true;

      await errFlow.scope<bool>(
        () => null,
        criticalIf: (_, __) => true,
        onCriticalError: (_, __) => r2 = true,
      );

      expect(r1, isFalse);
      expect(r2, isTrue);
    });
  });

  group('logger', () {
    test('logger is called with correct values', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.log('foo', _StackTrace('bar'), 'baz');
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, 'baz');
    });

    test('logger is called with correct values when context is omitted', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.log('foo', _StackTrace('bar'));
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, isNull);
    });

    test('calling set() calls the logger', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.set(null, 'foo', _StackTrace('bar'), 'baz');
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, 'baz');
    });

    test('assert() fails if no logger is set but exception is provided', () {
      expect(
        () => errFlow.log(null, _StackTrace('bar')),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'assert() fails if log() is called with stack/context but without exception',
      () {
        errFlow.useDefaultLogger();

        expect(
          () => errFlow.log(null, _StackTrace('bar'), 'baz'),
          throwsA(isA<AssertionError>()),
        );
      },
    );
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
