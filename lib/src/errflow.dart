import 'package:meta/meta.dart';

import 'notifier_impl.dart';

part 'notifier.dart';

/// A class that facilitates handling and logging of errors.
class ErrFlow<T> {
  /// Creates an ErrFlow that facilitates handling and logging of errors.
  ///
  /// The generic type [T] is the type of error values. The provided
  /// [defaultValue] is used as the initial value in notifiers,
  /// representing that there is no error initially in each [scope()].
  ErrFlow(T defaultValue) {
    _notifier = Notifier<T>(defaultValue)
      ..addListener(
        ({T? error, Object? exception, StackTrace? stack, Object? context}) {
          assert(
            exception == null || logger != null,
            'Information on an exception was provided by `set()` or `log()` '
            'while no logger is set.\n'
            'To fix, set a custom logger by assigning it to `logger`, '
            'or use the default logger by calling `useDefaultLogger()`.',
          );
          assert(
            (stack == null && context == null) || exception != null,
            'Only the stack trace and/or the context, without information '
            'about the exception, were provided by `set()` or `log()`.\n'
            'To fix, provide also the exception.',
          );

          if (logger != null && exception != null) {
            logger!(exception, stack, reason: context);
          }
        },
      );
  }

  late final Notifier<T> _notifier;

  /// The default error handler function for non-critical errors.
  ///
  /// If set, the function is used as the default handler that is called
  /// from [scope()] if `onError` is omitted.
  ///
  /// The value returned from the function executed by [scope()] and the
  /// last error are passed in, which are of type `S` and [T] respectively.
  void Function<S>(S, T)? errorHandler;

  /// The default error handler function for critical errors.
  ///
  /// If set, the function is used as the default handler that is called
  /// from [scope()] if `onCriticalError` is omitted.
  ///
  /// The value returned from the function executed by [scope()] and the
  /// last error are passed in, which are of type `S` and [T] respectively.
  void Function<S>(S, T)? criticalErrorHandler;

  /// A logger function that is called when an error is notified.
  ///
  /// The signature matches that of the `recordError()` method in the
  /// `firebase_crashlytics` package (although this logger does not have
  /// some named parameters existing in `recordError()`), and thus the
  /// `FirebaseCrashlytics.recordError` can be assigned to the logger as is
  /// if you want to leave logging operations to Crashlytics.
  Future<void> Function(Object, StackTrace?, {Object? reason})? logger;

  /// A getter for the value that was set in the constructor and is used as
  /// the initial value for [lastError] in an object of the [ErrNotifier]
  /// class and its variants in each [scope()].
  T? get defaultValue => _notifier.defaultValue;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_notifier.isDisposed) {
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

  /// Discards the resources used by the object. After this is called,
  /// the object is not in a usable state and should be discarded.
  void dispose() {
    _notifier.dispose();
  }

  /// Registers a listener, which is a function to be called when new
  /// error information is set by [ErrNotifier.set()], [ErrNotifier.log()],
  /// [LoggingErrNotifier.set()] or [LoggingErrNotifier.log()].
  ///
  /// This method must not be called after [dispose()] has been called.
  void addListener(ErrListener<T> listener) {
    assert(_debugAssertNotDisposed());
    _notifier.addListener(listener);
  }

  /// Removes a previously registered listener from the list of listeners.
  /// If the given listener is not registered, the call is ignored.
  ///
  /// This method must not be called after [dispose()] has been called.
  void removeListener(ErrListener<T> listener) {
    assert(_debugAssertNotDisposed());
    _notifier.removeListener(listener);
  }

  /// Sets the default logger to be used, which outputs information such
  /// as the message of an exception and the stack trace to the console.
  void useDefaultLogger() {
    assert(_debugAssertNotDisposed());
    logger = _defaultLogger;
  }

  Future<void> _defaultLogger(
    Object? exception,
    StackTrace? stack, {
    Object? reason,
  }) async {
    print(exception);
    if (stack != null) {
      print(stack);
    }
    if (reason != null) {
      print(reason);
    }
  }

  @override
  String toString() {
    final listenerCount =
        _notifier.isDisposed ? 'null' : _notifier.countListeners();
    final hasErrorHandler = errorHandler != null;
    final hasCriticalErrorHandler = criticalErrorHandler != null;
    final hasLogger = logger != null;
    final loggerType = logger == _defaultLogger ? 'default' : 'custom';

    return '$runtimeType#$hashCode('
        'listeners: $listenerCount, '
        'defaultValue: ${_notifier.defaultValue}, '
        'errorHandler: ${hasErrorHandler ? 'set' : 'null'}, '
        'criticalErrorHandler: ${hasCriticalErrorHandler ? 'set' : 'null'}, '
        'logger: ${hasLogger ? loggerType : 'null'})';
  }

  /// Executes the provided function [process], and then calls either of
  /// the [onError] and [onCriticalError] callbacks if the condition
  /// specified by [errorIf] or [criticalIf] is met respectively.
  ///
  /// A new object of [ErrNotifier] is passed to [process] to allow to call
  /// [ErrNotifier.set()] or [ErrNotifier.log()] on the object. Use the
  /// object also to access to [ErrNotifier.lastError] to see what the most
  /// resent error was. If there was no error, [ErrNotifier.lastError] holds
  /// the default value specified in the constructor of [ErrFlow].
  ///
  /// All of the other parameters are also functions, which receive the
  /// result of the [process] and the last error that occurred inside it.
  /// If there is no error, the default value is provided as the last error.
  ///
  /// [onError] (or [errorHandler] if [onError] is not specified) is called
  /// if [errorIf] returns true, and similarly, [onCriticalError] (or
  /// [criticalErrorHandler]) is called if [criticalIf] returns true.
  /// The condition of [criticalIf] is evaluated prior to that of [errorIf],
  /// and the latter is ignored if the former condition is met.
  Future<S> scope<S>(
    Future<S> Function(ErrNotifier<T>) process, {
    bool Function(S, T)? errorIf,
    bool Function(S, T)? criticalIf,
    void Function(S, T)? onError,
    void Function(S, T)? onCriticalError,
  }) async {
    assert(_debugAssertNotDisposed());
    assert(
      errorIf == null || onError != null || errorHandler != null,
      'The handler for non-critical errors is missing while `errorIf` '
      'is specified.\n'
      'To fix, set the default or a custom handler by assigning it '
      'to `errorHandler`.',
    );
    assert(
      criticalIf == null ||
          onCriticalError != null ||
          criticalErrorHandler != null,
      'The handler for critical errors is missing while `criticalErrorIf` '
      'is specified.\n'
      'To fix, set the default or a custom handler by assigning it to '
      '`criticalErrorHandler`.',
    );

    final newNotifier = Notifier.from(_notifier);
    final result = await process(newNotifier);
    final error = newNotifier.lastError!;

    // NOTE: criticalIf must be evaluated ahead of errorIf.
    if (criticalIf != null && criticalIf(result, error)) {
      onCriticalError == null
          ? criticalErrorHandler!(result, error)
          : onCriticalError(result, error);
    } else if (errorIf != null && errorIf(result, error)) {
      onError == null ? errorHandler!(result, error) : onError(result, error);
    }

    newNotifier.dispose();

    return result;
  }

  /// Executes the provided function [process] with an object of
  /// [LoggingErrNotifier] passed to it.
  ///
  /// The object can be used to call [LoggingErrNotifier.set()] and
  /// [LoggingErrNotifier.log()], but calls to [LoggingErrNotifier.set()]
  /// are forwarded to the logger.
  ///
  /// This is useful when you want errors set by [LoggingErrNotifier.set()]
  /// in [process] to be only logged instead of handled by the error
  /// handlers.
  Future<S> loggingScope<S>(
    Future<S> Function(LoggingErrNotifier<T>) process,
  ) async {
    assert(_debugAssertNotDisposed());

    final loggingNotifier = LoggingNotifier.from(_notifier);
    final result = await process(loggingNotifier);
    loggingNotifier.dispose();

    return result;
  }

  /// Executes the provided function [process] with an object of
  /// [IgnorableErrNotifier] passed to it.
  ///
  /// All calls on the object to [IgnorableErrNotifier.set()] and
  /// [IgnorableErrNotifier.log()] are ignored.
  ///
  /// This is useful when you want to prevent the error handlers and
  /// the logger from being triggered even if [IgnorableErrNotifier.set()]
  /// and [IgnorableErrNotifier.log()] are called inside [process].
  Future<S> ignorableScope<S>(
    Future<S> Function(IgnorableErrNotifier<T>) process,
  ) async {
    assert(_debugAssertNotDisposed());

    final ignorableNotifier = IgnorableNotifier.from(_notifier);
    final result = await process(ignorableNotifier);
    ignorableNotifier.dispose();

    return result;
  }
}
