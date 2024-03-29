// ignore_for_file: public_member_api_docs

import 'errflow.dart';

mixin _Base<T> {
  Set<ErrListener<T>> _listeners = {};
  T? _defaultValue;
  T? _lastError;
  bool _isDisposed = false;

  T? get defaultValue => _defaultValue;

  T? get lastError => _lastError;

  bool get hasError => _lastError != _defaultValue;

  bool get isDisposed => _isDisposed;

  void dispose() {
    _listeners.clear();
    _defaultValue = _lastError = null;
    _isDisposed = true;
  }

  void addListener(ErrListener<T> listener) {
    _listeners.add(listener);
  }

  void removeListener(ErrListener<T> listener) {
    _listeners.remove(listener);
  }

  int countListeners() {
    return _listeners.length;
  }

  String _toString(Type type) {
    return '$type#$hashCode('
        'listeners: ${countListeners()}, '
        'defaultValue: $_defaultValue, '
        'lastError: $_lastError)';
  }

  Never throwStateError() {
    throw StateError(
      'A ErrFlow<$T> was used after being disposed.\n'
      'Once you have called dispose() on a ErrFlow<$T>, '
      'it can no longer be used.',
    );
  }

  void set(T error, [Object? exception, StackTrace? stack, Object? context]) {
    if (_isDisposed) throwStateError();
    assert(error != null, '`null` cannot be passed to set() as an error.');

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

  void log(Object exception, [StackTrace? stack, Object? context]) {
    if (_isDisposed) throwStateError();

    for (final listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }
}

class Notifier<T> with _Base<T> implements ErrNotifier<T> {
  Notifier(T? defaultValue) {
    _defaultValue = defaultValue;
    _lastError = defaultValue;
  }

  Notifier.from(Notifier<T> notifier) {
    _defaultValue = notifier.defaultValue;
    _listeners = Set.of(notifier._listeners);
    _lastError = _defaultValue;
  }

  @override
  String toString() => _toString(ErrNotifier<T>);
}

class LoggingNotifier<T> with _Base<T> implements LoggingErrNotifier<T> {
  LoggingNotifier.from(Notifier<T> notifier) {
    _defaultValue = notifier.defaultValue;
    _listeners = Set.of(notifier._listeners);
    _lastError = _defaultValue;
  }

  @override
  String toString() => _toString(LoggingErrNotifier<T>);
}

class IgnorableNotifier<T> with _Base<T> implements IgnorableErrNotifier<T> {
  IgnorableNotifier.from(Notifier<T> notifier) {
    _defaultValue = notifier.defaultValue;
    _lastError = _defaultValue;
  }

  @override
  void set(T error, [Object? exception, StackTrace? stack, Object? context]) {
    if (_isDisposed) throwStateError();
    assert(error != null, '`null` cannot be passed to set() as an error.');

    _lastError = error;
  }

  @override
  void log(Object exception, [StackTrace? stack, Object? context]) {
    if (_isDisposed) throwStateError();
    // noop
  }

  @override
  String toString() => _toString(IgnorableErrNotifier<T>);
}
