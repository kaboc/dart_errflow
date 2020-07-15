import 'package:test/test.dart';

import 'package:errflow/errflow.dart';

void main() {
  final info = ErrInfo<int>();

  test('only remaining listeners are notified', () {
    final notification1 = _Notification();
    final notification2 = _Notification();

    info
      ..addListener(notification1.listener)
      ..set(1)
      ..addListener(notification2.listener)
      ..set(2)
      ..removeListener(notification1.listener)
      ..set(3)
      ..removeListener(notification2.listener)
      ..set(4);

    expect(notification1.values, <int>[1, 2]);
    expect(notification2.values, <int>[2, 3]);
  });

  test('cannot be used after disposed', () {
    final notification = _Notification();

    info
      ..addListener(notification.listener)
      ..set(1)
      ..dispose();

    expect(notification.values, <int>[1]);
    expect(() => info.set(2), throwsA(isA<AssertionError>()));
  });
}

class _Notification {
  List<int> values = <int>[];

  void listener({
    int type,
    dynamic exception,
    StackTrace stack,
    dynamic context,
  }) {
    values.add(type);
  }
}
