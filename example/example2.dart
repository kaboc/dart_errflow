import 'package:errflow/errflow.dart';

//===========================================================================
// An example of combiningScope().
// This example parses five strings to int and prints the following.
//
// '10' => 10
// '20' => 20
// [LOG] 'abc' - FormatException: Invalid radix-10 number (at character 1)
// [ERROR] Parsing failed.
// 'abc' => 0
// '40' => 40
// '50' => 50
//===========================================================================

enum AppError {
  parse,
}

class ErrorManager {
  late final errFlow = ErrFlow<AppError>()..logger = _logger;

  void dispose() {
    errFlow.dispose();
  }

  void _logger(Object e, StackTrace? s, {Object? reason}) {
    print("[LOG] '$reason' - ${e.toString().split('\n').first}");
  }
}

//===========================================================================

Future<void> main() async {
  final errorManager = ErrorManager();
  final errFlow = errorManager.errFlow;

  for (final value in ['10', '20', 'abc', '40', '50']) {
    // combiningScope() executes toInt(), logs an error if any, and
    // then returns the result containing both the computed result
    // and the error.
    //
    // The notifier passed by combiningScope is a LoggingErrNotifier.
    // Error handlers are not triggered with it, so you're responsible
    // for handling the error.
    final result = await errFlow.combiningScope(
      (notifier) => toInt(notifier, value),
    );

    // The result contains the last error too, so it is possible
    // to check and handle it outside of the scope.
    if (result.hasError) {
      switch (result.error!) {
        case AppError.parse:
          print('[ERROR] Parsing failed.');
      }
    }

    // The `value` always has an int value regardless of an error.
    print("'$value' => ${result.value}");
  }

  errorManager.dispose();
}

Future<int> toInt(ErrNotifier notifier, String text) async {
  try {
    return int.parse(text);
  } on Exception catch (e, s) {
    notifier.set(AppError.parse, e, s, text);
  }

  return 0;
}
