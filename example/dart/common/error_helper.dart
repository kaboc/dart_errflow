import 'package:errflow/errflow.dart';

import 'enum.dart';

export 'package:errflow/errflow.dart';
export 'enum.dart';

class ErrorHelper {
  ErrorHelper() {
    errFlow = ErrFlow<ErrorTypes>(ErrorTypes.none)
      ..logger = _logger
      ..errorHandler = _errorHandler
      ..criticalErrorHandler = _criticalErrorHandler;
  }

  ErrFlow<ErrorTypes> errFlow;

  void dispose() {
    errFlow.dispose();
  }

  void _logger(dynamic e, StackTrace _, {dynamic context}) {
    print('Logged: $e${context == null ? '' : ' ($context)'}');
  }

  void _errorHandler<T>(T result, ErrorTypes errorType) {
    print('Error: $errorType');
  }

  void _criticalErrorHandler<T>(T result, ErrorTypes errorType) {
    print('Critical error: $errorType');
  }
}
