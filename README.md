# errflow

[![Pub Version](https://img.shields.io/pub/v/errflow)](https://pub.dev/packages/errflow)
[![Dart CI](https://github.com/kaboc/dart_errflow/workflows/Dart%20CI/badge.svg)](https://github.com/kaboc/dart_errflow/actions)

A tiny Dart/Flutter package for making it somewhat easier to comprehend the flow of errors
and handle them.

## Usage

### Initialisation and clean-up

Instantiate `ErrFlow`, with the default error type representing that there is no error.

Make sure to call `dispose()` when `ErrFlow` is no longer needed.

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

Use `set()` to set an error type equivalent to an actual exception/error occurring when some
process of yours has failed, such as when an exception/error has occurred. The listener is
notified of the error type you set and stores it as the last error type so that it can be
checked later. The listener also logs the information on the exception/error if it is provided
via `set()` or `log()`.

```dart
Future<bool> yourMethod() {
  try {
    return errorProneProcess();
  } catch(e, s) {
    // This updates the last error type and also triggers logging.
    errFlow.set(ErrorTypes.foo, e, s, 'additional info');

    // Use log() instead if you consider the exception as
    // non-problematic and want to just log it.
    errFlow.log(e, s, 'additional info');
  }

  return false;
}
```

### Handling errors

`scope()` executes a function and handles errors occurring in the function, according to
specified conditions. Use both or either of `errorIf` and `criticalIf` to set the conditions
of whether to treat the result of the function as non-critical/critical errors.

You can customise the conditions for your preference by combining the function result and the
error type received. (e.g. A certain process should be treated as a success if the result is
valid regardless of a connection error, because data was not fetched from a remote server but
obtained instead from the local database successfully.)

If either of the conditions is met, the relevant handler of `onError` or `onCriticalError` is
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

### Default error handlers

You may want to consistently use a specific handler for non-critical errors, and the same or
another one for critical errors. In such a case, `errorHandler` and `criticalErrorHandler` will
come in handy. You can specify in advance how errors should be handled, and omit `onError` and
`onCriticalError` in `scope()`.

```dart
void _errorHandler<T>(T result, ErrorTypes type) {
  if (type == ErrorTypes.foo) {
    print('Critical error: $type');
  } else {
    print('Error: $type ($result)');
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

### Adding/removing a listener

This is usually unnecessary, but you can add a custom listener for your own needs.

```dart
void _listener({ErrorTypes type, dynamic exception, StackTrace stack, dynamic context}) {
  // Some processing
}

...

errFlow.addListener(_listener);

...

errFlow.removeListener(_listener);
```
