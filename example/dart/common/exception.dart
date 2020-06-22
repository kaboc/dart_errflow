class BaseException implements Exception {
  @override
  String toString() => runtimeType.toString();
}

class ExceptionA extends BaseException {}

class ExceptionB extends BaseException {}

class ExceptionC extends BaseException {}
