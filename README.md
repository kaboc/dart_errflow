# errflow

[![Pub Version](https://img.shields.io/pub/v/errflow)](https://pub.dev/packages/errflow)
[![Dart CI](https://github.com/kaboc/dart_errflow/workflows/Dart%20CI/badge.svg)](https://github.com/kaboc/dart_errflow/actions)

A Dart/Flutter package for making it somewhat easier to comprehend the flow of errors
and handle them.

## Usage

### Initialisation and clean-up

Instantiate [ErrFlow][errflow], with the default error type representing that there is no error.

Make sure to call [dispose()][dispose] when the object of [ErrFlow][errflow] is no longer needed.

```dart
enum ErrorTypes {
  none,
  foo,
  bar,
}

...

final errFlow = ErrFlow<ErrorTypes>(ErrorTypes.none);

...

errFlow.dispose();
```

### Setting/logging an error

Use [set()][set] to set a custom error type equivalent to the actual exception/error occurring
when some process of yours has failed. The listener is notified of the error type and stores it
as the last error type ([lastError][lasterror]) so that it can be checked later.

The listener also calls the [logger][logger] to log a set of information about an exception/error
if it is provided via [set()][set] or [log()][log].

```dart
Future<bool> yourMethod() {
  try {
    return errorProneProcess();
  } catch(e, s) {
    // This updates the last error type and also triggers logging.
    errFlow.set(ErrorTypes.foo, e, s, 'additional info');

    // Provide only the error type if logging is unnecessary.
    errFlow.set(ErrorTypes.foo);

    // Use log() instead, if you consider the exception as
    // non-problematic and want to just log it.
    errFlow.log(e, s, 'additional info');
  }

  return false;
}
```

Note that nothing will be logged unless the value of an exception/error is provided, even if
the stack trace and the context are given.

### Handling errors

[scope()][scope] executes a function, and handles errors occurring in there according to the
conditions specified by `errorIf` and `criticalIf`. Use both or either of them to set the
conditions of whether to treat the result of the function as non-critical/critical errors.

If either of the conditions is met, the relevant handler (`onError` or `onCriticalError`) is
called with the function result and the error type passed in. Do some error handling in these
handlers, like showing the error to the user.

```dart
final result = await errFlow.scope<bool>(
  () => yourMethod(),
  errorIf: (result, errorType) => errorType == ErrorTypes.foo,
  criticalIf: (result, errorType) => errorType == ErrorTypes.bar,
  onError: (result, errorType) => _onError(result, errorType),
  onCriticalError: (result, errorType) => _onCriticalError(result, errorType),
);
```

The handler functions receive the result and the error type, which means you can combine them
to customise the conditions for your preference.

e.g. To make the `onError` handler called when the process fails for reasons other than a
connection error:

```dart
errorIf: (result, errorType) => !result && errorType != ErrorTypes.connection
```

### Default error handlers

You may want to consistently use a particular handler for non-critical errors, and the same or
another one for critical errors. In such a case, `errorHandler` and `criticalErrorHandler` will
come in handy. You can specify in advance how errors should be handled, and omit `onError` and
`onCriticalError` in [scope()][scope].

```dart
void _errorHandler<T>(T result, ErrorTypes type) {
  if (type == ErrorTypes.foo) {
    // Handle the foo error
  } else {
    // Handle other errors
  }
}

...

errFlow
  ..errorHandler = _errorhandler
  ..criticalErrorHandler = _errorHandler;

final result = await errFlow.scope<bool>(
  () => yourMethod(),
  errorIf: (result, errorType) => !result,
);
```

### Logger

To use the default logger, which simply prints information to the console, call
[useDefaultLogger()][defaultlogger] before the first logging.

```dart
errFlow.useDefaultLogger();
```

If it is too simple and lacks functionality you need, set your own logger.

```dart
void _logger(dynamic e, StackTrace s, {dynamic context}) {
  if (type == ErrorTypes.foo || type == ErrorTypes.bar) {
    Crashlytics.instance.recordError(e, s, context: context);
  } else {
    print('Error: $e');
  }
}

...

errFlow.logger = _logger;
```

Set the default or a custom logger, otherwise an assertion error will occur in the debug mode.

### Adding/removing a listener

This is usually unnecessary, but you can add a custom listener for your special needs.

```dart
void _listener({ErrorTypes type, dynamic exception, StackTrace stack, dynamic context}) {
  // Some processing
}

...

errFlow.addListener(_listener);

...

errFlow.removeListener(_listener);
```

[errflow]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow-class.html
[dispose]: https://pub.dev/documentation/errflow/latest/info/ErrInfo/dispose.html
[set]: https://pub.dev/documentation/errflow/latest/info/ErrInfo/set.html
[log]: https://pub.dev/documentation/errflow/latest/info/ErrInfo/log.html
[logger]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/logger.html
[lasterror]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/lastError.html
[scope]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/scope.html
[defaultlogger]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/useDefaultLogger.html