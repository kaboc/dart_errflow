import 'package:meta/meta.dart';

/// Signature of callbacks that is called by [ErrInfo.set] and [ErrInfo.log].
typedef _Listener<T> = void Function({
  T type,
  dynamic exception,
  StackTrace stack,
  dynamic context,
});

/// A class that provides an error notification API.
///
/// This class is used as a mixin by [ErrFlow], but you can also use this
/// separately either directly or by extending or mixing in it.
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

  /// Registers a listener, which is a closure to be called when new
  /// information is set either by [set] or [log].
  ///
  /// This method must not be called after [dispose] has been called.
  void addListener(_Listener<T> listener) {
    assert(_debugAssertNotDisposed());
    _listeners.add(listener);
  }

  /// Removes a previously registered listener from the list of listeners.
  ///
  /// If the given listener is not registered, the call is ignored.
  ///
  /// This method must not be called after [dispose] has been called.
  void removeListener(_Listener<T> listener) {
    assert(_debugAssertNotDisposed());
    _listeners.remove(listener);
  }

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded (calls to
  /// [addListener] and [removeListener] will throw after the object is
  /// disposed).
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _listeners = null;
  }

  /// Calls all the registered listeners with error information including
  /// the error type.
  ///
  /// Use this method when clients need to be notified of a new error.
  ///
  /// This method must not be called after [dispose] has been called.
  void set(T type, [dynamic exception, StackTrace stack, dynamic context]) {
    assert(_debugAssertNotDisposed());

    for (final listener in _listeners) {
      listener(
        type: type,
        exception: exception,
        stack: stack,
        context: context,
      );
    }
  }

  /// Calls all the registered listeners with error information, but without
  /// the type unlike in [set].
  ///
  /// Use this method when clients need to be notified of a new error,
  /// generally for the purpose of logging.
  ///
  /// This method must not be called after [dispose] has been called.
  void log(dynamic exception, [StackTrace stack, dynamic context]) {
    assert(_debugAssertNotDisposed());

    for (final listener in _listeners) {
      listener(exception: exception, stack: stack, context: context);
    }
  }
}
