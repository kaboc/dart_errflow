import 'info.dart';

class ErrFlow<T> with ErrInfo<T> {
  ErrFlow(this.defaultError) {
    _lastError = defaultError;

    addListener(
      ({T type, dynamic exception, StackTrace stack, dynamic context}) {
        assert((exception != null && logger != null) ||
            (stack == null && context == null));

        if (type != null) {
          _lastError = type;
        }
        if (logger != null && exception != null) {
          logger(exception, stack, context: context);
        }
      },
    );
  }

  final T defaultError;
  T _lastError;
  void Function(dynamic, StackTrace, {dynamic context}) logger;
  void Function<S>(S, T) errorHandler;
  void Function<S>(S, T) criticalErrorHandler;

  T get lastError => _lastError;


  void useDefaultLogger() {
    logger = (dynamic exception, StackTrace stack, {dynamic context}) {
      print(exception);
      if (stack != null) {
        print(stack);
      }
      if (context != null) {
        print(context);
      }
    };
  }

  Future<S> scope<S>(
    Future<S> Function() process, {
    bool Function(S, T) errorIf,
    bool Function(S, T) criticalIf,
    void Function(S, T) onError,
    void Function(S, T) onCriticalError,
  }) async {
    assert(process != null);
    assert(errorIf == null || (onError != null || errorHandler != null));
    assert(criticalIf == null ||
        (onCriticalError != null || criticalErrorHandler != null));

    _lastError = defaultError;
    final S result = await process();

    // NOTE: criticalIf must be evaluated ahead of errorIf as it matters more.
    if (criticalIf != null && criticalIf(result, _lastError)) {
      onCriticalError == null
          ? criticalErrorHandler(result, _lastError)
          : onCriticalError(result, _lastError);
    } else if (errorIf != null && errorIf(result, _lastError)) {
      onError == null
          ? errorHandler(result, _lastError)
          : onError(result, _lastError);
    }

    return result;
  }
}
