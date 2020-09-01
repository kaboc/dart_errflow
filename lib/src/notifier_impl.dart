import 'errflow.dart';

mixin _State<T> {
  Set<ErrListener<T>> _listeners;
  T _defaultValue;
  T _lastError;

  T get defaultValue => _defaultValue;
  T get lastError => _lastError;
  bool get hasError => _lastError != _defaultValue;

  void dispose() {
    _lastError = _listeners = null;
  }

  void addListener(ErrListener<T> listener) {
    assert(_listeners != null);
    _listeners.add(listener);
  }

  void removeListener(ErrListener<T> listener) {
    assert(_listeners != null);
    _listeners.remove(listener);
  }

  int countListeners() {
    assert(_listeners != null);
    return _listeners.length;
  }

  String _toString(Type type) {
    return '$type#$hashCode('
        'listeners: ${_listeners == null ? 'null' : countListeners()}, '
        'lastError: $lastError)';
  }
}

class Notifier<T> with _State<T> implements ErrNotifier<T> {
  Notifier(T defaultValue, {Set<ErrListener<T>> listeners}) {
    _defaultValue = defaultValue;
    _listeners = listeners ?? {};
    _lastError = defaultValue;
  }

  Notifier.from(Notifier<T> notifier) {
    assert(notifier._listeners != null);

    _defaultValue = notifier.defaultValue;
    _listeners = Set.of(notifier._listeners);
    _lastError = _defaultValue;
  }

  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(_listeners != null);
    assert(error != null);

    _lastError = error;

    for (final listener in _listeners) {
      listener(
        error: error,
        exception: exception,
        stack: stack,
        context: context,
      );
    }
  }

  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]) {
    assert(_listeners != null);

    for (final listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }

  @override
  String toString() => _toString((<T>() => T)<ErrNotifier<T>>());
}

class LoggingNotifier<T> with _State<T> implements LoggingErrNotifier<T> {
  LoggingNotifier.from(Notifier<T> notifier) {
    assert(notifier._listeners != null);

    _defaultValue = notifier.defaultValue;
    _listeners = Set.of(notifier._listeners);
    _lastError = _defaultValue;
  }

  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(_listeners != null);
    assert(error != null);

    _lastError = error;
    log(exception, stack, context);
  }

  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]) {
    assert(_listeners != null);

    for (final listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }

  @override
  String toString() => _toString((<T>() => T)<LoggingErrNotifier<T>>());
}

class IgnorableNotifier<T> with _State<T> implements IgnorableErrNotifier<T> {
  IgnorableNotifier.from(Notifier<T> notifier) {
    assert(notifier._listeners != null);

    _defaultValue = notifier.defaultValue;
    _lastError = _defaultValue;
  }

  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(error != null);
    _lastError = error;
  }

  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]) {}

  @override
  String toString() => _toString((<T>() => T)<IgnorableErrNotifier<T>>());
}
