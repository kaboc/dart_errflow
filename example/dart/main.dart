import 'dart:io';

import 'common/error_helper.dart';
import 'model.dart';

Future<void> main() async {
  final errorHelper = ErrorHelper();
  await _App(errorHelper)._waitInput();

  errorHelper.dispose();
}

class _App {
  _App(this.errorHelper) : _model = Model(errorHelper.errFlow.info);

  final ErrorHelper errorHelper;
  final Model _model;

  Future<void> _waitInput() async {
    print(
      'A value between 1 and 1000 is randomly generated.\n'
      'It is treated as an error if the value is a multiple of N (3 - 5):\n'
      '  - 3: minor error that can be ignored\n'
      '  - 4: minor error\n'
      '  - 5: critical error\n',
    );

    while (true) {
      print("Input 'q' to quit, or other strings to execute:");

      final input = stdin.readLineSync();
      if (input == 'q') {
        break;
      }

      print('-' * 50);
      print('Processing...\nWait for a sec please.');

      final result = await _execProcess();

      _showResult(result);
    }
  }

  Future<bool> _execProcess() async {
    return await errorHelper.errFlow.scope<bool>(
      () => _model.someProcess(),

      // You don't necessarily have to specify both errorIf and criticalIf.
      // Omit errorIf if you want to ignore non-critical errors, or omit
      // criticalIf if you are sure the errors that may occur in the process
      // will never be critical.
      errorIf: (result, type) => !result && type == ErrorTypes.minor,
      criticalIf: (result, type) => !result && type != ErrorTypes.minor,
    );
  }

  void _showResult(bool result) {
    if (result) {
      final hasMinorError = errorHelper.errFlow.lastError != ErrorTypes.none;
      print(
        'Completed successfully'
        '${hasMinorError ? ' (minor error was ignored)' : ''}.',
      );
    } else {
      print('Failed.');
    }
    print('-' * 50);
  }
}
