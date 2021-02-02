part of 'errflow.dart';

/// Signature for a listener used in [ErrNotifier] and other classes that
/// extend it or hold its instance.
///
/// [error] is an error value of type [T] (e.g. your custom error type).
/// [exception] and [stack] are usually an object of the `Exception` class
/// or of its subclass, and the stack trace of the exception. [context]
/// can be whatever information to be added to a log.
typedef ErrListener<T> = void Function({
  T? error,
  Object? exception,
  StackTrace? stack,
  Object? context,
});

/// A class that provides an error notification API.
@sealed
abstract class ErrNotifier<T> {
  /// The latest error value that was notified most recently.
  T? get lastError;

  /// Whether or not there was an error. `true` is returned if [lastError]
  /// is not equal to the default value.
  bool get hasError;

  /// Sets [error] to [lastError], and then calls all the registered
  /// listeners with the error passed in, along with related information
  /// if provided.
  void set(T error, [Object? exception, StackTrace? stack, Object? context]);

  /// Calls all the registered listeners with error information, but
  /// without the error value unlike in [set()].
  void log(Object exception, [StackTrace? stack, Object? context]);
}

/// A variant of [ErrNotifier] used in [ErrFlow.loggingScope()].
/// This notifier itself is the same as [ErrNotifier], but because
/// [ErrFlow.loggingScope()] has no parameters for error conditions,
/// calling [set()] does not trigger the error handlers.
@sealed
abstract class LoggingErrNotifier<T> extends ErrNotifier<T> {}

/// A variant of [ErrNotifier] used in [ErrFlow.ignorableScope()].
/// Calling [set()] and [log()].with this notifier does not trigger
/// the error handlers, the logger, nor added listener functions.
@sealed
abstract class IgnorableErrNotifier<T> extends ErrNotifier<T> {
  /// Only sets [error] to [lastError].
  @override
  void set(T error, [Object? exception, StackTrace? stack, Object? context]);

  /// Does nothing.
  @override
  void log(Object exception, [StackTrace? stack, Object? context]);
}
