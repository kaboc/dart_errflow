import 'package:test/test.dart';

import 'package:errflow/src/notifier_impl.dart';

void main() {
  group('ErrNotifier', () {
    final notifier = Notifier<int>(10);

    test('default value is set as lastError', () {
      expect(notifier.lastError, equals(10));
    });

    test('set() updates last error', () {
      notifier.set(1);
      expect(notifier.lastError, equals(1));
    });

    test('set() calls listener functions', () {
      final notification = _Notification();
      notifier
        ..addListener(notification.listener)
        ..set(1, 'foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, equals([1]));
      expect(notification.exceptions, equals(['foo']));
      expect(notification.stacks, equals(['bar']));
      expect(notification.contexts, equals(['baz']));
    });

    test('log() calls listener functions', () {
      final notification = _Notification();
      notifier
        ..addListener(notification.listener)
        ..log('foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, equals(<int>[]));
      expect(notification.exceptions, equals(['foo']));
      expect(notification.stacks, equals(['bar']));
      expect(notification.contexts, equals(['baz']));
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

      expect(notification1.errors, equals(<int>[1, 2]));
      expect(notification2.errors, equals(<int>[2, 3]));
    });

    test('hasError returns an appropriate value', () {
      final newNotifier = Notifier<int>(10);
      expect(newNotifier.hasError, isFalse);

      newNotifier.set(1);
      expect(newNotifier.hasError, isTrue);
    });
  });

  group('LoggingErrNotifier', () {
    final notifier = Notifier<int>(10);
    final loggingNotifier = LoggingNotifier<int>.from(notifier);

    test('set() updates last error', () {
      loggingNotifier.set(1);
      expect(loggingNotifier.lastError, equals(1));
    });

    test('set() does not update last error in original object', () {
      loggingNotifier.set(1);
      expect(notifier.lastError, equals(10));
    });

    test('set() calls listener functions', () {
      final notification = _Notification();
      loggingNotifier
        ..addListener(notification.listener)
        ..set(1, 'foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, equals(<int>[1]));
      expect(notification.exceptions, equals(['foo']));
      expect(notification.stacks, equals(['bar']));
      expect(notification.contexts, equals(['baz']));
    });

    test('log() calls listener functions', () {
      final notification = _Notification();
      loggingNotifier
        ..addListener(notification.listener)
        ..log('foo', _StackTrace('bar'), 'baz');

      expect(notification.errors, equals(<int>[]));
      expect(notification.exceptions, equals(['foo']));
      expect(notification.stacks, equals(['bar']));
      expect(notification.contexts, equals(['baz']));
    });

    test('hasError returns an appropriate value', () {
      final newLoggingNotifier = LoggingNotifier<int>.from(notifier);
      expect(newLoggingNotifier.hasError, isFalse);

      newLoggingNotifier.set(1);
      expect(newLoggingNotifier.hasError, isTrue);
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

    test('set() updates last error', () {
      ignorableNotifier.set(1);
      expect(ignorableNotifier.lastError, equals(1));
    });

    test('set() does not update last error in original object', () {
      ignorableNotifier.set(1);
      expect(notifier.lastError, equals(10));
    });

    test('hasError returns an appropriate value', () {
      final newIgnorableNotifier = IgnorableNotifier<int>.from(notifier);
      expect(newIgnorableNotifier.hasError, isFalse);

      newIgnorableNotifier.set(1);
      expect(newIgnorableNotifier.hasError, isTrue);
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
      expect(notification.errors, equals(<int>[1]));
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
  List exceptions = <Object>[];
  List stacks = <String>[];
  List contexts = <Object>[];

  void listener(
      {int? error, Object? exception, StackTrace? stack, Object? context}) {
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
