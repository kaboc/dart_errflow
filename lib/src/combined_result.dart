import 'package:meta/meta.dart';

/// A class that holds both a value and an error as a result of
/// some computation.
@sealed
abstract class CombinedResult<S, T> {
  // ignore: public_member_api_docs
  const CombinedResult({
    required this.value,
    required this.error,
    required this.hasError,
  });

  /// The result of some computation.
  ///
  /// This value always exists despite an error in the computation.
  final S value;

  /// The error that occurred in some computation if an error occurred;
  /// otherwise a value representing the state where there is no error.
  ///
  /// This may or may not be `null` in the latter case.
  /// It depends on how this class is used.
  final T? error;

  /// Whether [error] has a value representing some error.
  ///
  /// Having a non-null value in [error] does not necessarily mean
  /// that an error occurred, so refer to this for the existence
  /// of an error rather than checking the value of the [error].
  ///
  /// e.g. In some implementation, `0` instead of `null` held in
  /// [error] may indicate that no error has occurred.
  final bool hasError;

  @override
  String toString() {
    return 'CombinedResult(value: $value, error: $error, hasError: $hasError)';
  }
}
