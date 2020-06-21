import 'package:test/test.dart';

import 'package:errflow/errflow.dart';

void main() {
  final ErrFlow<int> errFlow = ErrFlow<int>(100);

  group('lastError', () {
    test('default error is set to lastError on initialisation', () {
      expect(errFlow.lastError, 100);
    });

    test('lastError is updated when set() is called', () {
      errFlow.info.set(200);
      expect(errFlow.lastError, 200);
    });
  });

  group('function passed to scope()', () {
    test('assertion error if the function is null', () {
      expect(errFlow.scope<void>(null), throwsA(isA<AssertionError>()));
    });

    test('error is reset to default when the function is called', () {
      errFlow.info.set(200);

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
    test('assertion error if onError is missing', () async {
      expect(
        () => errFlow.scope<void>(
          () => null,
          errorIf: (_, __) => null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('onError is called only when errorIf is true', () async {
      int v = 0;

      await errFlow.scope<String>(
        () => null,
        errorIf: (String result, int value) => false,
        onError: (String result, int value) => v = 1,
      );
      expect(v, 0);

      await errFlow.scope<String>(
        () => null,
        errorIf: (String result, int value) => true,
        onError: (String result, int value) => v = 2,
      );
      expect(v, 2);
    });

    test('errorIf and onError get correct values', () async {
      errFlow.scope<String>(
        () => Future<String>.delayed(Duration.zero, () {
          errFlow.info.set(200);
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
    test('assertion error if onCriticalError is missing', () async {
      expect(
        () => errFlow.scope<void>(
          () => null,
          criticalIf: (_, __) => null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('onCriticalError is called only when criticalIf is true', () async {
      int v = 0;

      await errFlow.scope<String>(
        () => null,
        criticalIf: (String result, int value) => false,
        onCriticalError: (String result, int value) => v = 1,
      );
      expect(v, 0);

      await errFlow.scope<String>(
        () => null,
        criticalIf: (String result, int value) => true,
        onCriticalError: (String result, int value) => v = 2,
      );
      expect(v, 2);
    });

    test('criticalIf and onCriticalError get correct values', () async {
      errFlow.scope<String>(
        () => Future<String>.delayed(Duration.zero, () {
          errFlow.info.set(200);
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

  group('logger', () {
    test('logger is called with correct values', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.info.log('foo', _StackTrace('bar'), 'baz');
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, 'baz');
    });

    test('logger is called with correct values when context is omitted', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.info.log('foo', _StackTrace('bar'));
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, null);
    });

    test('calling set() calls the logger', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.info.set(null, 'foo', _StackTrace('bar'), 'baz');
      expect(log.exception, 'foo');
      expect(log.stack.toString(), 'bar');
      expect(log.context, 'baz');
    });

    test('calling set() does not call the logger if exception is null', () {
      final _Log log = _Log();
      errFlow.logger = log.logger;

      errFlow.info.set(null, null, _StackTrace('bar'), 'baz');
      expect(log.exception, null);
      expect(log.stack, null);
      expect(log.context, null);
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
