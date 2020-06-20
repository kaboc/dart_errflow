import 'dart:math';

import 'package:errflow/info.dart';

import 'common/enum.dart';
import 'common/exception.dart';

class Model {
  const Model(this.errInfo);

  final ErrInfo<ErrorTypes> errInfo;

  /// A process that calls an error-prone process, handles the exception
  /// raised there, and notifies the corresponding error.
  Future<bool> someProcess() async {
    try {
      return await errorProneProcess();
    } on ExceptionA catch (e, s) {
      errInfo.set(ErrorTypes.critical, e, s);
    } on ExceptionB catch (e, s) {
      errInfo.set(ErrorTypes.minor, e, s);
    } on ExceptionC catch (e, s) {
      // Returns true as success ignoring this exception, but
      // logs the fact that an exception occurred.
      errInfo.log(e, s, 'ignored');
      return true;
    } catch (e, s) {
      errInfo.set(ErrorTypes.unknown, e, s);
    }

    return false;
  }

  /// Some process that takes a while and can raise an exception.
  Future<bool> errorProneProcess() async {
    return Future.delayed(const Duration(seconds: 1), () {
      final int value = Random().nextInt(1000) + 1;
      print('Generated: $value');

      if (value % 5 == 0) {
        throw ExceptionA();
      } else if (value % 4 == 0) {
        throw ExceptionB();
      } else if (value % 3 == 0) {
        throw ExceptionC();
      }

      return true;
    });
  }
}
