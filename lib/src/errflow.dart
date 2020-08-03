import 'info.dart';

/// A class that listens for error notifications to handle and log them.
class ErrFlow<T> with ErrInfo<T> {
  /// Creates a class that listens for error notifications to handle and
  /// log them.
  ///
  /// The generic type [T] is the type of the error types. The provided
  /// [defaultError] is used as the error type representing that there
  /// is no error.
  ErrFlow(this.defaultError) {
    _lastError = defaultError;

    addListener(
      ({T type, dynamic exception, StackTrace stack, dynamic context}) {
        assert(exception == null || logger != null, '''
Information on an exception/error was provided by `set()` or `log()`
while no logger is set.
To fix, set a custom logger by assigning it to `logger`,
or use the default logger by calling `useDefaultLogger()`.
''');
        assert((stack == null && context == null) || exception != null, '''
Only the stack trace and/or the context, without information about
the exception/error, were provided by `set()` or `log()`.
To fix, provide also the exception/error.
''');

        if (type != null) {
          _lastError = type;
        }
        if (logger != null && exception != null) {
          logger(exception, stack, context: context);
        }
      },
    );
  }

  /// The default error type of type [T] that represents no error.
  ///
  /// The last error type is reset to this value on every call of [scope].
  final T defaultError;

  T _lastError;

  /// The error type that was notified most recently.
  ///
  /// The value of [defaultError] is set to this as the initial error type,
  /// and set again on every call of [scope].
  T get lastError => _lastError;

  /// The default error handler function for non-critical errors.
  ///
  /// If set, the function is used as the default handler that is called
  /// from [scope] if `onError` is omitted.
  ///
  /// The value returned from the function executed by [scope] and the last
  /// error type are passed in, which are of type `S` and [T] respectively.
  void Function<S>(S, T) errorHandler;

  /// The default error handler function for critical errors.
  ///
  /// If set, the function is used as the default handler that is called
  /// from [scope] if `onCriticalError` is omitted.
  ///
  /// The value returned from the function executed by [scope] and the last
  /// error type are passed in, which are of type `S` and [T] respectively.
  void Function<S>(S, T) criticalErrorHandler;

  /// A logger function that is called when an error is notified with
  /// information on an exception provided.
  ///
  /// This signature matches that of the `recordError()` method in the
  /// official Firebase Crashlytics package, and thus the method can be
  /// used as the logger as is if you like.
  void Function(dynamic, StackTrace, {dynamic context}) logger;

  /// Sets the default logger to be used, which outputs information such as
  /// the message of an exception and the stack trace to the console.
  void useDefaultLogger() {
    logger = (dynamic exception, StackTrace stack, {dynamic context}) {
      print(exception);
      if (stack != null) {
        print(stack);
      }
      if (context != null) {
        print(context);
      }
    };
  }

  /// Executes the provided function [process], and then calls either of
  /// the [onError] and [onCriticalError] callbacks consequently if the
  /// condition specified by [errorIf] or [criticalIf] is met respectively.
  ///
  /// Every time this method is called, [lastError] is reset to the value
  /// of [defaultError] before [process] is executed.
  ///
  /// The generic type [S] is the type of the value returned by [process].
  /// All of the other parameters are also functions, which receive the
  /// result of the [process] and the last error type.
  ///
  /// [onError] is called if [errorIf] returns true, and similarly
  /// [onCriticalError] is called if [criticalIf] returns true.
  /// If [errorIf] is specified, either [onError] or [errorHandler] must
  /// be specified too. The same applies to [criticalIf] and
  /// [onCriticalError] / [criticalErrorHandler].
  Future<S> scope<S>(
    Future<S> Function() process, {
    bool Function(S, T) errorIf,
    bool Function(S, T) criticalIf,
    void Function(S, T) onError,
    void Function(S, T) onCriticalError,
  }) async {
    assert(process != null);
    assert(errorIf == null || (onError != null || errorHandler != null), '''
The handler for non-critical errors is missing while `errorIf` is specified.
To fix, set the default or a custom handler by assigning it to `errorHandler`.
''');
    assert(
        criticalIf == null ||
            (onCriticalError != null || criticalErrorHandler != null),
        '''
The handler for critical errors is missing while `criticalErrorIf` is specified.
To fix, set the default or a custom handler by assigning it to `criticalErrorHandler`.
''');

    _lastError = defaultError;
    final result = await process();

    // NOTE: criticalIf must be evaluated ahead of errorIf.
    if (criticalIf != null && criticalIf(result, _lastError)) {
      onCriticalError == null
          ? criticalErrorHandler(result, _lastError)
          : onCriticalError(result, _lastError);
    } else if (errorIf != null && errorIf(result, _lastError)) {
      onError == null
          ? errorHandler(result, _lastError)
          : onError(result, _lastError);
    }

    return result;
  }
}
