## 0.4.0-nullsafety.2 - 11 February 2021

* Allow the default error value to be null.
* Minor improvements of documentation, tests, etc.

## 0.4.0-nullsafety.1 - 2 February 2021

* Fix the issue of `Loggingnotifier.set()` not passing the provided error to listeners.
* Fix the signatures of the default logger and some others to match `ErrFlow.logger`.
* Change the return types of scopes and logger from `Future` to `FutureOr`.
* Minor improvements of documentation, tests, etc.

## 0.4.0-nullsafety.0 - 30 November 2020

* Migrate to null safety.

## 0.3.0 - 25 September 2020

* **BREAKING CHANGE**
    * Change logger signature in accordance with new api of flutter_crashlytics package.
* Update documentation and dependencies.

## 0.2.2 - 2 September 2020

* Internal changes
    * Rename `defaultError` to `defaultValue`.
    * Change `_State` class to `mixin`.
    * Change factory constructors to named constructors.
* New features
    * Add `toString()` to each public class for better outputs by `print()`.
    * Add `defaultValue` to `ErrFlow`.
    * Add `hasError` to `ErrNotifier`, `LoggingErrNotifier` and `IgnorableErrNotifier`.
* Small improvements of documentation

## 0.2.1 - 24 August 2020

* Fix inheritance relationship of IgnorableNotifier to be consistent with other classes.

## 0.2.0 - 24 August 2020

* Correct version number.
    * Minor version number should have been incremented for the last breaking changes.

## 0.1.4 - 20 August 2020

* **BREAKING CHANGES** to fix a serious flaw in concurrency.
    * Major API changes.
        * `ErrFlow` does not extend `ErrInfo`.
        * `ErrInfo` is renamed to `ErrNotifier`.
        * The first parameter of a listener is renamed from `type` to `error`.
        * An `ErrNotifier` object is passed to the function executed by `scope()`.
            * `set()` and `log()` need to be called on the passed object.
        * `lastError` is a property of `ErrNotifier`, not of `ErrFlow`.
        * `loggingScope()` and `ignorableScope()` are added.
    * File containing `ErrNotifier` cannot be imported separately.
    * Update documentation, tests and example.

## 0.1.3 - 3 August 2020

* Improve README.
* Explain assertion errors.

## 0.1.2 - 15 July 2020

* Enable omit_local_variable_types rule.
* Minor updates of documentation.

## 0.1.1 - 12 July 2020

* Minor updates of documentation.
* Lower the `meta` version to avoid a dependency issue.

## 0.1.0 - 12 July 2020

* Initial release
