import 'package:test/test.dart';

import 'package:errflow/src/notifier_impl.dart';

void main() {
  group('ErrNotifier', () {
    final notifier = Notifier<int>(10);

    test('default value is set as lastError', () {
      expect(notifier.lastError, 10);
    });

    test('assert() fails if set() is called without error value', () {
      expect(
        () => notifier.set(null),
        throwsA(isA<AssertionError>()),
      );
    });

    test('calling set() updates last error', () {
      notifier.set(1);
      expect(notifier.lastError, 1);
    });

    test('calling set() notifies listeners', () {
      final notification = _Notification();
      notifier
        ..addListener(notification.listener)
        ..set(1, 'foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, [1]);
      expect(notification.exceptions, ['foo']);
      expect(notification.stacks, ['bar']);
      expect(notification.contexts, ['baz']);
    });

    test('calling log() notifies listeners', () {
      final notification = _Notification();
      notifier
        ..addListener(notification.listener)
        ..log('foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, <int>[]);
      expect(notification.exceptions, ['foo']);
      expect(notification.stacks, ['bar']);
      expect(notification.contexts, ['baz']);
    });

    test('only remaining listeners are notified', () {
      final notification1 = _Notification();
      final notification2 = _Notification();

      notifier
        ..addListener(notification1.listener)
        ..set(1)
        ..addListener(notification2.listener)
        ..set(2)
        ..removeListener(notification1.listener)
        ..set(3)
        ..removeListener(notification2.listener)
        ..set(4);

      expect(notification1.errors, <int>[1, 2]);
      expect(notification2.errors, <int>[2, 3]);
    });
  });

  group('LoggingErrNotifier', () {
    final notifier = Notifier<int>(10);
    final loggingNotifier = LoggingNotifier<int>.from(notifier);

    test('calling set() updates last error', () {
      loggingNotifier.set(1);
      expect(loggingNotifier.lastError, 1);
    });

    test('calling set() does not update last error in original object', () {
      loggingNotifier.set(1);
      expect(notifier.lastError, 10);
    });

    test('a call to set() is forwarded to log()', () {
      final notification = _Notification();
      loggingNotifier
        ..addListener(notification.listener)
        ..set(1, 'foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, <int>[]);
      expect(notification.exceptions, ['foo']);
      expect(notification.stacks, ['bar']);
      expect(notification.contexts, ['baz']);
    });

    test('calling log() notifies listeners', () {
      final notification = _Notification();
      loggingNotifier
        ..addListener(notification.listener)
        ..log('foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, <int>[]);
      expect(notification.exceptions, ['foo']);
      expect(notification.stacks, ['bar']);
      expect(notification.contexts, ['baz']);
    });
  });

  group('IgnorableErrNotifier', () {
    final notifier = Notifier<int>(10);
    final ignorableNotifier = IgnorableNotifier<int>.from(notifier);

    test('addListener() is unavailable', () {
      expect(
        () => ignorableNotifier.addListener(_Notification().listener),
        throwsA(isA<AssertionError>()),
      );
    });

    test('calling set() updates last error', () {
      ignorableNotifier.set(1);
      expect(ignorableNotifier.lastError, 1);
    });

    test('calling set() does not update last error in original object', () {
      ignorableNotifier.set(1);
      expect(notifier.lastError, 10);
    });
  });

  group('dispose', () {
    final notifier = Notifier<int>(10);
    final notification = _Notification();

    notifier
      ..addListener(notification.listener)
      ..set(1)
      ..dispose();

    test('cannot be used after disposed', () {
      expect(notification.errors, <int>[1]);
      expect(() => notifier.set(2), throwsA(isA<AssertionError>()));
    });

    test('calling toString() after dispose() causes no error', () {
      expect(
        () => notifier.toString(),
        isNot(throwsA(isA<AssertionError>())),
      );
    });
  });
}

class _Notification {
  List errors = <int>[];
  List exceptions = <dynamic>[];
  List stacks = <String>[];
  List contexts = <dynamic>[];

  void listener(
      {int error, dynamic exception, StackTrace stack, dynamic context}) {
    if (error != null) {
      errors.add(error);
    }
    if (exception != null) {
      exceptions.add(exception);
    }
    if (stack != null) {
      stacks.add(stack.toString());
    }
    if (context != null) {
      contexts.add(context);
    }
  }
}

class _StackTrace extends StackTrace {
  _StackTrace(this.value);

  final String value;

  @override
  String toString() => value;
}
