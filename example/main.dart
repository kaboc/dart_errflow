import 'package:errflow/errflow.dart';

enum CustomError {
  none,
  critical,
}

final errFlow = ErrFlow<CustomError>(CustomError.none);

Future<void> main() async {
  errFlow
    ..logger = logger
    ..criticalErrorHandler = errorHandler;

  for (var i = -2; i <= 2; i++) {
    // Executes the dividedBy() method, and calls criticalErrorHandler
    // if the last error is critical at the point when the method ends.
    final result = await errFlow.scope<int>(
      (notifier) => dividedBy(notifier, 10, i),
      criticalIf: (result, error) => error == CustomError.critical,
    );
    print('= $result');
  }

  errFlow.dispose();
}

void logger(Object e, StackTrace? s, {Object? reason}) {
  print('Logged: $e');
}

void errorHandler<T>(T result, CustomError? error) {
  print('Error: $error');
}

int dividedBy(ErrNotifier notifier, int v1, int v2) {
  print('\n$v1 ~/ $v2');

  var result = 0;

  // Treats the exception caused by division by zero as a critical error,
  // and logs other exceptions (which in fact never occur in this example).
  try {
    result = v1 ~/ v2;
  } on IntegerDivisionByZeroException catch (e, s) {
    notifier.set(CustomError.critical, e, s);
  } on Exception catch (e, s) {
    notifier.log(e, s);
  }

  return result;
}
