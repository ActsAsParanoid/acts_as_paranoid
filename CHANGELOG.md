# CHANGELOG

Notable changes to this project will be documented in this file.

## 0.6.3

* Update Travis CI configuration ([#137], by [Matijs van Zuijlen][mvz]).
* Add predicate to check if record was soft deleted or hard deleted ([#136],
  by [Aymeric Le Dorze][aymeric-ledorze]).
* Add support for recover! method ([#75], by [vinoth][avinoth]).
* Fix a record being dirty after destroying it ([#135], by
  [Aymeric Le Dorze][aymeric-ledorze]).

## 0.6.2

* Prevent recovery of non-deleted records
  ([#133], by [Mary Beliveau][marycodes2] and [Valerie Woolard][valeriecodes])
* Allow model to set `table_name` after `acts_as_paranoid` macro
  ([#131], by [Alex Wheeler][AlexWheeler]).
* Make counter cache work with a custom column name and with optional
  associations ([#123], by [Ned Campion][nedcampion]).

## 0.6.1

* Add support for Rails 6 ([#124], by [Daniel Rice][danielricecodes],
  [Josh Bryant][jbryant92], and [Romain Alexandre][RomainAlexandre])
* Add support for incrementing and decrementing counter cache columns on
  associated objects ([#119], by [Dimitar Lukanov][shadydealer])
* Add `:double_tap_destroys_fully` option, with default `true` ([#116],
  by [Michael Riviera][ri4a]).
* Officially support Ruby 2.6 ([#114], by [Matijs van Zuijlen][mvz]).

## 0.6.0 and earlier

(To be added)

<!-- Contributors -->

[ri4a]: https://github.com/ri4a
[mvz]: https://github.com/mvz
[shadydealer]: https://github.com/shadydealer
[danielricecodes]: https://github.com/danielricecodes
[jbryant92]: https://github.com/jbryant92
[nedcampion]: https://github.com/nedcampion
[RomainAlexandre]: https://github.com/RomainAlexandre
[AlexWheeler]: https://github.com/AlexWheeler
[marycodes2]: https://github.com/marycodes2
[valeriecodes]: https://github.com/valeriecodes
[aymeric-ledorze]: https://github.com/aymeric-ledorze
[avinoth]: https://github.com/avinoth

<!-- issues & pull requests -->

[#137]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/137
[#136]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/136
[#135]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/135
[#133]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/133
[#131]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/131
[#124]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/124
[#123]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/123
[#119]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/119
[#116]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/116
[#114]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/114
[#75]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/75
