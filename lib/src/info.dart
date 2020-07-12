typedef _Listener<T> = void Function({
  T type,
  dynamic exception,
  StackTrace stack,
  dynamic context,
});

class ErrInfo<T> {
  List<_Listener<T>> _listeners = <_Listener<T>>[];

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_listeners == null) {
        throw AssertionError(
          'A $runtimeType was used after being disposed.\n'
          'Once you have called dispose() on a $runtimeType, '
          'it can no longer be used.',
        );
      }
      return true;
    }());
    return true;
  }

  void addListener(_Listener<T> listener) {
    assert(_debugAssertNotDisposed());
    _listeners.add(listener);
  }

  void removeListener(_Listener<T> listener) {
    assert(_debugAssertNotDisposed());
    _listeners.remove(listener);
  }

  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
  }

  void set(T type, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(_debugAssertNotDisposed());

    for (final _Listener<T> listener in _listeners) {
      listener(
        type: type,
        exception: exception,
        stack: stack,
        context: context,
      );
    }
  }

  void log(dynamic exception, StackTrace stack, [dynamic context]) {
    assert(_debugAssertNotDisposed());

    for (final _Listener<T> listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }
}
