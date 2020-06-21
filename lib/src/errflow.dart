import 'info.dart';

class ErrFlow<T> {
  ErrFlow(this.defaultError) {
    _lastError = defaultError;
    _info.addListener(
      ({T type, dynamic exception, StackTrace stack, dynamic context}) {
        if (type != null) {
          _lastError = type;
        }
        if (logger != null && exception != null) {
          logger(exception, stack, context: context);
        }
      },
    );
  }

  final ErrInfo<T> _info = ErrInfo<T>();
  T defaultError;
  T _lastError;
  void Function(dynamic, StackTrace, {dynamic context}) logger;

  ErrInfo<T> get info => _info;
  T get lastError => _lastError;

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
    assert(f != null);
    assert(errorIf == null || onError != null);
    assert(criticalIf == null || onCriticalError != null);

    _lastError = defaultError;
    final T2 result = await f();

    // NOTE: criticalIf should be evaluated before errorIf as it matters more.
    if (criticalIf != null && criticalIf(result, _lastError)) {
      onCriticalError(result, _lastError);
    } else if (errorIf != null && errorIf(result, _lastError)) {
      onError(result, _lastError);
    }

    return result;
  }
}
