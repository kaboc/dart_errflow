import 'package:errflow/errflow.dart';

//===========================================================================
// A basic example.
// This example parses five strings to int and prints the following.
//
// '10' => 10
// '20' => 20
// [LOG] 'abc' - FormatException: Invalid radix-10 number (at character 1)
// [CRITICAL] AppError.critical
// 'abc' => 0
// '40' => 40
// '50' => 50
//===========================================================================

enum AppError {
  none,
  critical,
}

// A special class like this is good for keeping handlers tidy.
class ErrorManager {
  late final errFlow = ErrFlow<AppError>(AppError.none)
    ..logger = _logger
    ..errorHandler = _errorHandler // not used in this example
    ..criticalErrorHandler = _criticalErrorHandler;

  void dispose() {
    errFlow.dispose();
  }

  void _logger(Object e, StackTrace? s, {Object? reason}) {
    print("[LOG] '$reason' - ${e.toString().split('\n').first}");
  }

  void _errorHandler<T>(T result, AppError? error) {
    print('[ERROR] $error');
  }

  void _criticalErrorHandler<T>(T result, AppError? error) {
    print('[CRITICAL] $error');
  }
}

//===========================================================================

Future<void> main() async {
  final errorManager = ErrorManager();
  final errFlow = errorManager.errFlow;

  for (final value in ['10', '20', 'abc', '40', '50']) {
    // scope() executes toInt(), and calls criticalErrorHandler
    // if the last error is critical at the point when the method ends,
    // as well as logging the error.
    final result = await errFlow.scope(
      (notifier) => toInt(notifier, value),
      criticalIf: (result, error) => error == AppError.critical,
    );
    print("'$value' => $result");
  }

  errorManager.dispose();
}

int toInt(ErrNotifier notifier, String text) {
  // Treats FormatException caused by int.parse() as a critical error, and
  // only logs other exceptions (which in fact never occur in this example).
  try {
    return int.parse(text);
  } on FormatException catch (e, s) {
    notifier.set(AppError.critical, e, s, text);
  } on Exception catch (e, s) {
    notifier.log(e, s, text);
  }

  return 0;
}
