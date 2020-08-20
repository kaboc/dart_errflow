part of 'errflow.dart';

/// Signature for a listener used in [ErrNotifier] and other classes that
/// extend it or hold its instance.
///
/// [error] is an error value of type [T] (e.g. your custom error type).
/// [exception] and [stack] are usually an object of the `Exception` class
/// or of its subclass, and the stack trace of the exception. [context]
/// can be whatever information to be added to a log.
typedef ErrListener<T> = void Function({
  T error,
  dynamic exception,
  StackTrace stack,
  dynamic context,
});

/// A class that provides an error notification API.
@sealed
abstract class ErrNotifier<T> {
  /// The latest error value that was notified most recently.
  T get lastError;

  /// Calls all the registered listeners with error information including
  /// the error value, the exception, etc.
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]);

  /// Calls all the registered listeners with error information, but
  /// without the error value unlike in [set()].
  void log(dynamic exception, [StackTrace stack, dynamic context]);
}

/// A variant of [ErrNotifier] that proxies calls to the [set()] method
/// to [log()].
@sealed
abstract class LoggingErrNotifier<T> extends ErrNotifier<T> {
  /// Updates [lastError] and delegates the notification task to [log()].
  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]);

  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]);
}

/// A variant of [ErrNotifier] that does not have listeners and ignores calls
/// to [set()] and [log()].
@sealed
abstract class IgnorableErrNotifier<T> extends ErrNotifier<T> {
  /// Only updates [lastError].
  @override
  void set(T error, [dynamic exception, StackTrace stack, dynamic context]);

  /// Does nothing.
  @override
  void log(dynamic exception, [StackTrace stack, dynamic context]);
}
