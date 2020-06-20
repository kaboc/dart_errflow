typedef _Listener<T> = void Function({
  T type,
  dynamic exception,
  StackTrace stack,
  dynamic context,
});

class ErrInfo<T> {
  List<_Listener<T>> _listeners = <_Listener<T>>[];

  void dispose() {
    _listeners = null;
  }

  void addListener(_Listener<T> listener) {
    _listeners.add(listener);
  }

  void removeListener(_Listener<T> listener) {
    _listeners.remove(listener);
  }

  void set(T type, [dynamic exception, StackTrace stack, dynamic context]) {
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
    for (final _Listener<T> listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }
}
