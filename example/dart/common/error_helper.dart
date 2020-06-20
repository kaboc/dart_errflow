import 'package:errflow/errflow.dart';

import 'enum.dart';

export 'package:errflow/errflow.dart';
export 'enum.dart';

class ErrorHelper {
  final errFlow = ErrFlow<ErrorTypes>(ErrorTypes.none)
    ..logger = (dynamic e, _, {dynamic context}) {
      print('Logged: $e${context == null ? '' : ' ($context)'}');
    };

  void dispose() {
    errFlow.dispose();
  }

  void onError(dynamic result, ErrorTypes errorType) {
    print('Error: $errorType');
  }

  void onCriticalError(dynamic result, ErrorTypes errorType) {
    print('Critical error: $errorType');
  }
}
