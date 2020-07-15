// Run this file with assertion enabled by `dart --enable-asserts main.dart`

import 'package:errflow/errflow.dart';

enum ErrorTypes {
  none,
  critical,
}

final errFlow = ErrFlow<ErrorTypes>(ErrorTypes.none);

Future<void> main() async {
  errFlow
    ..logger = logger
    ..criticalErrorHandler = errorHandler;

  for (var i = -2; i <= 2; i++) {
    final result = await errFlow.scope<int>(
      () async => dividedBy(10, i),
      criticalIf: (result, type) => type == ErrorTypes.critical,
    );

    if (errFlow.lastError != ErrorTypes.critical) {
      print('= $result');
    }
  }

  errFlow.dispose();
}

void logger(dynamic e, StackTrace s, {dynamic context}) {
  print('Logged: $e');
}

void errorHandler<T>(T result, ErrorTypes type) {
  print('Error: $type');
}

int dividedBy(int v1, int v2) {
  print('\n$v1 ~/ $v2');

  int result;

  // If the divisor is
  // - a negative value
  //     => AssertionError (not treated as an error but just logged)
  // - zero
  //     => IntegerDivisionByZeroException (treated as a critical error)
  try {
    result = v1 ~/ v2;
    assert(v2 >= 0);
  } on AssertionError catch (e, s) {
    errFlow.log(e, s);
  } catch (e) {
    errFlow.set(ErrorTypes.critical, e);
    return 0;
  }

  return result;
}
