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
