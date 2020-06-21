import 'package:test/test.dart';

import 'package:errflow/errflow.dart';

void main() {
  final ErrInfo<int> info = ErrInfo<int>();

  test('only remaining listeners are notified', () {
    final _Notification notification1 = _Notification();
    final _Notification notification2 = _Notification();

    notification1.addListener(info);
    info.set(1);
    notification2.addListener(info);
    info.set(2);
    notification1.removeListener(info);
    info.set(3);
    notification2.removeListener(info);
    info.set(4);

    expect(notification1.list, <int>[1, 2]);
    expect(notification2.list, <int>[2, 3]);
  });

  test('cannot be used after disposed', () {
    final _Notification notification = _Notification();

    notification.addListener(info);
    info.set(1);
    info.dispose();

    expect(notification.list, <int>[1]);
    expect(() => info.set(2), throwsNoSuchMethodError);
  });
}

class _Notification {
  List<int> list = <int>[];

  void listener({
    int type,
    dynamic exception,
    StackTrace stack,
    dynamic context,
  }) {
    list.add(type);
  }

  void addListener(ErrInfo<int> info) {
    info.addListener(listener);
  }

  void removeListener(ErrInfo<int> info) {
    info.removeListener(listener);
  }
}
