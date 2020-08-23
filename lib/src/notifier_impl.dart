import 'errflow.dart';

class _State<T> {
  Set<ErrListener<T>> _listeners;
  T _lastError;

  T get lastError => _lastError;

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
}

class Notifier<T> with _State<T> implements ErrNotifier<T> {
  Notifier(T defaultError, {Set<ErrListener<T>> listeners})
      : _defaultError = defaultError {
    _listeners = listeners ?? {};
    _lastError = defaultError;
  }

  factory Notifier.from(Notifier<T> notifier) {
    assert(notifier._listeners != null);

    return Notifier<T>(
      notifier._defaultError,
      listeners: Set.of(notifier._listeners),
    );
  }

  final T _defaultError;

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
}

class LoggingNotifier<T> with _State<T> implements LoggingErrNotifier<T> {
  LoggingNotifier(T defaultError, {Set<ErrListener<T>> listeners}) {
    _listeners = listeners ?? {};
    _lastError = defaultError;
  }

  factory LoggingNotifier.from(Notifier<T> notifier) {
    assert(notifier._listeners != null);

    return LoggingNotifier(
      notifier._defaultError,
      listeners: Set.of(notifier._listeners),
    );
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
}

class IgnorableNotifier<T> with _State<T> implements IgnorableErrNotifier<T> {
  IgnorableNotifier(T defaultError) {
    _lastError = defaultError;
  }

  factory IgnorableNotifier.from(Notifier<T> notifier) {
    return IgnorableNotifier(notifier._defaultError);
  }

  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(error != null);
    _lastError = error;
  }

  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]) {}
}
