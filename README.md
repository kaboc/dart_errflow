[![Pub Version](https://img.shields.io/pub/v/errflow)](https://pub.dev/packages/errflow)
[![Dart CI](https://github.com/kaboc/dart_errflow/workflows/Dart%20CI/badge.svg)](https://github.com/kaboc/dart_errflow/actions)

A Dart package for easier and more comprehensible flow of error handling and logging.

## Motivation

I made this package because I found it hard to handle exceptions:

- An app stops on an exception if it is not caught.
- It is sometimes unclear if an exception has already been caught somewhere.
- It is not preferable to catch an exception in a different layer that should be agnostic
  about things specific to the original layer (e.g. a DB error / a network error).
- However, it is difficult to return an error value (instead of the exception itself to
  avoid the above issue) together with the result of some processing from a method to its
  caller located in another layer.

Solutions:

- [Result][result] in `package:async`
- `package:errflow` (this package)

These look very different, but roughly speaking, they are similar in that they provide
a way to pass a result and/or an error from a method to the caller; the former holds either
of the values, and the latter allows the caller to evaluate both values.

A big difference is that this package also provides handlers and a logger to enable errors
to be handled more easily in a unified manner. It makes it possible that error handling
is centralized.

## Usage

### Initialisation and clean-up

Instantiate [ErrFlow][errflow], with the default value representing that there is no error.
The value is used as the initial value in the notifier of each [scope()][scope].

When the [ErrFlow][errflow] object is no longer needed, call [dispose()][dispose] to ensure
that the resources held in the object will not be used any more.

```dart
enum CustomError {
  none,
  foo,
  bar,
}

...

final errFlow = ErrFlow<CustomError>(CustomError.none);

...

errFlow.dispose();
```

If you prefer using `Exception` and its subtypes instead of a custom error type, specify
`Exception` as the error type, and pass `null` or none to the constructor to use `null`
as the default value.

```dart
final errFlow = ErrFlow<Exception>();
```

### Setting/logging an error

The notifier passed to the callback function of [scope()][scope] has the [set()][set] method
used for updating the error value and calling the logger, and the [log()][log] method for
only triggering the logger.

1. Use [scope()][scope] to pass an [ErrNotifier][notifier] to a function that can cause an error.
2. Call [set()][set] on the notifier when some error happens in the function.
3. The listener is notified of the error and stores it as the last error ([lastError][lasterror])
   so that it can be checked later inside the function.
4. The listener also calls the [logger][logger] to log a set of information about the error
   if it is provided via [set()][set] or [log()][log].
5. One of the error handlers is called after the callback completes if a condition to
   call it is met.

Error handlers are explained in detail later in this document.

```dart
final result = await errFlow.scope<bool>(
  (notifier) => yourFunc(notifier),
  ...,
);
```

```dart
Future<bool> yourFunc(ErrNotifier notifier) async {
  try {
    await errorProneProcess();
  } catch (e, s) {
    // This updates the last error value and also triggers the logger.
    notifier.set(CustomError.foo, e, s, 'additional info');
  }

  // If necessary, you can use hasError to check if some error was set.
  if (notifier.hasError) {
    ...
    return false;
  }

  return true;
}
```

You can also use only the first argument of [set()][set] to not trigger the logger:

```dart
notifier.set(CustomError.foo);
```

or use [log()][log] for only logging:

```dart
notifier.log(e, s, 'additional info');
```

***Isn't it inconvenient to have to pass a notifier?***

It is not impossible to remove the hassle to have to pass over an object of
[ErrNotifier][notifier], but I choose not to do so because method signatures with a
parameter of type `ErrNotifier` help you spot which methods require error handling.

### Handling an error

[scope()][scope] executes a function, and handles an error that has occurred inside there at
the point when the function finishes according to the conditions specified by `errorIf` and
`criticalIf`. Use both or either of them to set the conditions of whether to treat the function
result as a non-critical/critical error. The condition of `criticalIf` is evaluated prior to
that of `errorIf`.

If either of the conditions is met, the relevant handler, `onError` or `onCriticalError`, is
called. Do some error handling in these handlers, like showing different messages depending
on the severity of the error.

```dart
final result = await errFlow.scope<bool>(
  (notifier) => yourMethod(notifier),

  // Use both or only either of errorIf and criticalIf.
  errorIf: (result, error) => error == CustomError.foo,
  criticalIf: (result, error) => error == CustomError.bar,

  // There is a way to avoid writing onError and onCriticalError
  // every time, which is explained later.
  onError: (result, error) => _onError(result, error),
  onCriticalError: (result, error) => _onCriticalError(result, error),
);
```

The handler functions receive the function result and the error value, which means you can
combine them to tweak the conditions for triggering the handlers.

e.g. To trigger the `onError` handler if any error was set:

```dart
errorIf: (result, error) => error != errFlow.defaultError
```

e.g. To trigger the `onError` handler when the process fails for reasons other than a
connection error:

```dart
errorIf: (result, error) => !result && error != CustomError.connection
```

### Handling an error manually

[combiningScope()][combining-scope] is useful when you want to manually check and handle
an error, leaving only its logging to ErrFlow. 

It basically works like [loggingScope()][logging-scope] (described later), but returns
[CombinedResult][combined-result] that has both a function result and an error.
Using the combined result, it is possible to handle the error after the scope finishes.

```dart
final result = await errFlow.combiningScope(
  (notifier) => yourMethod(notifier),
);

if (result.hasError) {
  switch (result.error!) {
    case AppError.init:
      print('[ERROR] Initialization failed.');
  }
}
```

`CombinedResult` is similar to `Result` of package:async, but with some clear differences:

- It has both a value and an error, whereas `Result` has only either of them.
- It always has a value regardless of an error.
- The default error value is set to `error` if there was no error.
    - Having a non-null value in `error` does not always mean an error has occurred.

### Ignoring errors

If a method, in which [set()][set] can be used, is called from some different places in
your code, you may want to show an error message at some of them but not at the other places.
It is possible with the use of [loggingScope()][logging-scope] and [ignorableScope()][ignorable-scope],
allowing you to only log errors without handling them, or ignore them completely.

*loggingScope()*

`notifier` passed from [loggingScope()][logging-scope] is an object of
[LoggingErrNotifier][logging-notifier]. Calling [set()][logging-set] on that object only
updates the value of [lastError][lasterror] and triggers the logger (and added listener
functions), without triggering the error handlers.

```dart
final result = await errFlow.loggingScope<bool>(
  (LoggingErrNotifier notifier) => yourMethod(notifier),
);

bool yourMethod(ErrNotifier notifier) {
  try {
    return ...;
  } catch (e, s) {
    notifier.set(CustomError.foo, e, s);  // Only updates lastError and logs the error.
    return false;
  }
}
```

*ignorableScope()*

`notifier` passed from [ignorableScope()][ignorable-scope] is an object of
[IgnorableErrNotifier][ignorable-notifier]. Calling [set()][ignorable-set] and
[log()][ignorable-log] on that object does not trigger the error handlers nor the logger.
[set()][ignorable-set] only updates the value of [lastError][lasterror].

```dart
final result = await errFlow.ignorableScope<bool>(
  (IgnorableErrNotifier notifier) => yourMethod(notifier),
);

bool yourMethod(ErrNotifier notifier) {
  try {
    return ...;
  } catch (e, s) {
    notifier.set(CustomError.foo, e, s);  // Only updates lastError.
    return false;
  }
}
```

### Default error handlers

You may want to consistently use a particular handler for non-critical errors, and the same or
another one for critical errors. In such a case, `errorHandler` and `criticalErrorHandler` will
come in handy. You can specify in advance how errors should be handled, and omit `onError` and
`onCriticalError` in each [scope()][scope].

```dart
void _errorHandler<T>(T result, CustomError? error) {
  switch (error) {
    case CustomError.foo:
      // Handle the foo error (e.g. showing the error details)
      break;
    default:
      // Handle other errors
      break;
  }
}

...

errFlow
  ..errorHandler = _errorhandler
  ..criticalErrorHandler = _errorHandler;

final result = await errFlow.scope<bool>(
  (notifier) => yourMethod(notifier),
  errorIf: (result, error) => !result,
);
```

### Logger

To use the default logger, which simply prints information to the console, call
[useDefaultLogger()][defaultlogger] before the first logging.

```dart
errFlow.useDefaultLogger();
```

If it lacks functionality you need, set your own logger.

```dart
// The return type can be Future or non-Future.
// Note: Even if a Future is returned, set() and log() won't await it.
void _logger(Object e, StackTrace? s, {Object? reason}) {
  // Logging operations
}

...

errFlow.logger = _logger;
```

In flutter, the `recordError()` method of the firebase_crashlytics package can be assigned
to the logger as is.

```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

...

errFlow.logger = FirebaseCrashlytics.recordError;
```

Make sure to set the default or a custom logger, otherwise an assertion error will occur
in the debug mode.

### Adding/removing a listener

This is usually unnecessary, but you can add a custom listener for your special needs.

```dart
void _listener({CustomError? error, Object? exception, StackTrace? stack, Object? context}) {
  // Some processing
}

...

errFlow.addListener(_listener);

...

errFlow.removeListener(_listener);
```

[errflow]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow-class.html
[notifier]: https://pub.dev/documentation/errflow/latest/errflow/ErrNotifier-class.html
[logging-notifier]: https://pub.dev/documentation/errflow/latest/errflow/LoggingErrNotifer-class.html
[ignorable-notifier]: https://pub.dev/documentation/errflow/latest/errflow/IgnorableErrNotifier-class.html
[dispose]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/dispose.html
[set]: https://pub.dev/documentation/errflow/latest/errflow/ErrNotifier/set.html
[log]: https://pub.dev/documentation/errflow/latest/errflow/ErrNotifier/log.html
[logging-set]: https://pub.dev/documentation/errflow/latest/errflow/LoggingErrNotifier/set.html
[logging-log]: https://pub.dev/documentation/errflow/latest/errflow/LoggingErrNotifier/log.html
[ignorable-set]: https://pub.dev/documentation/errflow/latest/errflow/IgnorableErrNotifier/set.html
[ignorable-log]: https://pub.dev/documentation/errflow/latest/errflow/IgnorableErrNotifier/log.html
[logger]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/logger.html
[lasterror]: https://pub.dev/documentation/errflow/latest/errflow/ErrNotifier/lastError.html
[scope]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/scope.html
[logging-scope]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/loggingScope.html
[ignorable-scope]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/ignorableScope.html
[combining-scope]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/combiningScope.html
[defaultlogger]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/useDefaultLogger.html
[result]: https://pub.dev/documentation/async/latest/async/Result-class.html
[combined-result]: https://pub.dev/documentation/errflow/latest/errflow/CombinedResult-class.html
