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
      (notifier) async => dividedBy(notifier, 10, i),
      criticalIf: (result, error) => error == ErrorTypes.critical,
    );
    print('= $result');
  }

  errFlow.dispose();
}

void logger(dynamic e, StackTrace s, {dynamic context}) {
  print('Logged: $e');
}

void errorHandler<T>(T result, ErrorTypes error) {
  print('Error: $error');
}

int dividedBy(ErrNotifier notifier, int v1, int v2) {
  print('\n$v1 ~/ $v2');

  int result;

  try {
    result = v1 ~/ v2;
  } on IntegerDivisionByZeroException catch (e, s) {
    notifier.set(ErrorTypes.critical, e, s);
  } on Exception catch (e, s) {
    notifier.log(e, s);
  }

  return result;
}
