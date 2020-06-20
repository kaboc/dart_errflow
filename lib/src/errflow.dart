import 'info.dart';

class ErrFlow<T> {
  ErrFlow(this.defaultErrorType) {
    _info.addListener(
      ({T type, dynamic exception, StackTrace stack, dynamic context}) {
        if (type != null) {
          _lastType = type;
        }
        if (logger != null && exception != null) {
          logger(exception, stack, context: context);
        }
      },
    );
  }

  final ErrInfo<T> _info = ErrInfo<T>();
  T defaultErrorType;
  T _lastType;
  void Function(dynamic, StackTrace, {dynamic context}) logger;

  ErrInfo<T> get info => _info;
  T get lastError => _lastType;

  void dispose() {
    _info.dispose();
  }

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

  Future<T2> scope<T2>(
    Future<T2> Function() f, {
    bool Function(T2, T) errorIf,
    bool Function(T2, T) criticalIf,
    void Function(T2, T) onError,
    void Function(T2, T) onCriticalError,
  }) async {
    assert(errorIf == null || onError != null);
    assert(criticalIf == null || onCriticalError != null);

    _lastType = defaultErrorType;
    final T2 result = await f();

    // NOTE: criticalIf should be evaluated before errorIf as it matters more.
    if (criticalIf != null && criticalIf(result, _lastType)) {
      onCriticalError(result, _lastType);
    } else if (errorIf != null && errorIf(result, _lastType)) {
      onError(result, _lastType);
    }

    return result;
  }
}
