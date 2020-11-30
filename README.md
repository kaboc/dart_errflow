# errflow

[![Pub Version](https://img.shields.io/pub/v/errflow)](https://pub.dev/packages/errflow)
[![Dart CI](https://github.com/kaboc/dart_errflow/workflows/Dart%20CI/badge.svg)](https://github.com/kaboc/dart_errflow/actions)

A Dart/Flutter package for making it somewhat easier to comprehend the flow of errors
and handle them.

---

**apologies for the breaking changes in v0.1.4.**  
Please see the [Changelog](https://pub.dev/packages/errflow/changelog) for the list of the changes.  
The package should be safer now in exchange for the inconvenience caused by them.

---

## Motivation

I made this package because I found it cumbersome to handle exceptions:

- An app stops on an exception if it is not caught.
- It is sometimes unclear if an exception has already been caught somewhere.
- It is not preferable to catch an exception in a different layer that should be agnostic
  about a specific exception (e.g. a DB error / a network error).
- However, it is difficult to return an error value (instead of the exception itself to
  avoid the above issue) together with the result of some processing from a method to its
  caller located in another layer.

Solutions:

- [Result][result] in `package:async`
- `errflow` (this package)

These look different, but roughly speaking, they are similar in that they provide a way
to pass a result and an error value from a method to the caller.
The former uses a notifier passed from a caller to notify values to the caller, and the
latter returns a `Result` object that can hold either of those values.

A big difference is that this package also provides handlers and a logger to enable errors
to be handled more easily in a unified manner.

***Isn't it also cumbersome to have to pass a notifier?***

It is probably possible to remove the bother to pass an object of [ErrNotifier][notifier],
but I choose not to do so because method signatures with a parameter of type `ErrNotifier`
helps you spot that the methods require error handling.

## Usage

### Initialisation and clean-up

Instantiate [ErrFlow][errflow], with the default value representing that there is no error.
The value is used as the initial value in the notifier of each [scope()][scope].

When the [ErrFlow][errflow] object is no longer needed, call [dispose()][dispose] to ensure
that the resources held in the object will not be used any more.

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

1. Call [set()][set] on an [ErrNotifier][notifier] object when some exception happens.
    - The object is passed from [scope()][scope], which is described [later](#handling-errors)
      in this document.
2. The listener is notified of the error and stores it as the last error ([lastError][lasterror])
   so that it can be checked later inside the function executed by [scope()][scope].
3. The listener also calls the [logger][logger] to log a set of information about the exception
   if it is provided via [set()][set] or [log()][log].

```dart
Future<bool> yourMethod(ErrNotifier notifier) {
  try {
    return errorProneProcess();
  } catch(e, s) {
    // This updates the last error value and also triggers logging.
    notifier.set(ErrorTypes.foo, e, s, 'additional info');

    // Provide only the error value if logging is unnecessary.
    notifier.set(ErrorTypes.foo);

    // Use log() instead, if you consider the exception as
    // non-problematic and want to just log it.
    notifier.log(e, s, 'additional info');
  }

  // You can use hasError to check if some error was set.
  if (notifier.hasError) {
    ...
  }

  return false;
}
```

### Handling errors

[scope()][scope] executes a function, and handles errors occurring inside there when the function
finishes according to the conditions specified by `errorIf` and `criticalIf`. Use both or either
of them to set the conditions of whether to treat the function result as a non-critical/critical
error. The condition of `criticalIf` is evaluated prior to that of `errorIf`.

If either of the conditions is met, the relevant handler, `onError` or `onCriticalError`, is
called. Do some error handling in these handlers, like showing different messages depending
on the severity of the error.

```dart
final result = await errFlow.scope<bool>(
  (notifier) => yourMethod(notifier),
  errorIf: (result, error) => error == ErrorTypes.foo,
  criticalIf: (result, error) => error == ErrorTypes.bar,
  onError: (result, error) => _onError(result, error),
  onCriticalError: (result, error) => _onCriticalError(result, error),
);
```

The handler functions receive the function result and the error value, which means you can
combine them to customise the conditions for your preference.

e.g. To trigger the `onError` handler if any error was set:

```dart
errorIf: (result, error) => error != errFlow.defaultError
```

e.g. To trigger the `onError` handler when the process fails for reasons other than a
connection error:

```dart
errorIf: (result, error) => !result && error != ErrorTypes.connection
```

### Ignoring errors

If a method, in which [set()][set] is called on an exception, is called from some different
places in your code, you may want to show an error message at some of them but not at the others.
In such a case, you can control whether to handle the error, only log it instead of handling
it, or ignore it completely.

*loggingScope()*

`notifier` passed from [loggingScope][logging-scope] is an object of
 [LoggingErrNotifier][logging-notifier]. Calls on that object to [set()][logging-set] are
forwarded to [log()][logging-log], meaning that the error handlers are not triggered.

```dart
await errFlow.loggingScope<bool>(
  (notifier) => yourMethod(notifier),
);
```

*ignorableScope()*

`notifier` passed from [ignorableScope][ignorable-scope] is an object of
[IgnorableErrNotifier][ignorable-notifier]. Calls on that object to [set()][ignorable-set]
and [log()][ignorable-log] are ignored, meaning that both the error handlers and the logger
are not triggered.

```dart
await errFlow.ignorableScope<bool>(
  (notifier) => yourMethod(notifier),
);
```

### Default error handlers

You may want to consistently use a particular handler for non-critical errors, and the same or
another one for critical errors. In such a case, `errorHandler` and `criticalErrorHandler` will
come in handy. You can specify in advance how errors should be handled, and omit `onError` and
`onCriticalError` in [scope()][scope].

```dart
void _errorHandler<T>(T result, ErrorTypes error) {
  switch (error) {
    case ErrorTypes.foo:
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
Future<void> _logger(dynamic e, StackTrace s, {dynamic reason}) async {
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
void _listener({ErrorTypes error, dynamic exception, StackTrace stack, dynamic context}) {
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
[defaultlogger]: https://pub.dev/documentation/errflow/latest/errflow/ErrFlow/useDefaultLogger.html

[result]: https://pub.dev/documentation/async/latest/async/Result-class.html
