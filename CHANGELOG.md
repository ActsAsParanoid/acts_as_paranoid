# CHANGELOG

Notable changes to this project will be documented in this file.

## UNRELEASED

* Update RuboCop and its configuration ([#171], by [Matijs van Zuijlen][mvz])
* Adding example with `destroyed_fully?` and `deleted_fully?` to the readme
  ([#170], by [Kiril Mitov][thebravoman])
* Updates version number instructions for installing gem ([#164], by [Kevin McAlear][kevinmcalear])
* Update rubocop ([#163], by [Matijs van Zuijlen][mvz])
* Fix ruby 2.7 keyword argument deprecation warning ([#161], by [Jon Riddle][wtfspm])
* Use correct unscope syntax so unscope works on Rails Edge ([#160], by [Matijs van Zuijlen][mvz])
* Update RuboCop and fix some offenses ([#159], by [Matijs van Zuijlen][mvz])
* Simplify validation override ([#158], by [Matijs van Zuijlen][mvz])
* Improve dev experience ([#157], by [Matijs van Zuijlen][mvz])
* Silence warnings ([#156], by [Matijs van Zuijlen][mvz])
* Update RuboCop ([#152], by [Matijs van Zuijlen][mvz])
* Add SimpleCov ([#150], by [Matijs van Zuijlen][mvz])
* Add rubocop ([#148], by [Matijs van Zuijlen][mvz])
* Handle `with_deleted` association option as a scope ([#147], by [Matijs van Zuijlen][mvz])
* Document save after destroy behavior ([#146], by [Matijs van Zuijlen][mvz])
* Update set of supported rubies to 2.4-2.7 ([#144], by [Matijs van Zuijlen][mvz])
* Support Rails 5.2+ only ([#126], by [Daniel Rice][danielricecodes])

## 0.6.3

* Update Travis CI configuration ([#137], by [Matijs van Zuijlen][mvz])
* Add predicate to check if record was soft deleted or hard deleted ([#136],
  by [Aymeric Le Dorze][aymeric-ledorze])
* Add support for recover! method ([#75], by [vinoth][avinoth])
* Fix a record being dirty after destroying it ([#135], by
  [Aymeric Le Dorze][aymeric-ledorze])

## 0.6.2

* Prevent recovery of non-deleted records
  ([#133], by [Mary Beliveau][marycodes2] and [Valerie Woolard][valeriecodes])
* Allow model to set `table_name` after `acts_as_paranoid` macro
  ([#131], by [Alex Wheeler][AlexWheeler])
* Make counter cache work with a custom column name and with optional
  associations ([#123], by [Ned Campion][nedcampion])

## 0.6.1

* Add support for Rails 6 ([#124], by [Daniel Rice][danielricecodes],
  [Josh Bryant][jbryant92], and [Romain Alexandre][RomainAlexandre])
* Add support for incrementing and decrementing counter cache columns on
  associated objects ([#119], by [Dimitar Lukanov][shadydealer])
* Add `:double_tap_destroys_fully` option, with default `true` ([#116],
  by [Michael Riviera][ri4a])
* Officially support Ruby 2.6 ([#114], by [Matijs van Zuijlen][mvz])

## 0.6.0 and earlier

(To be added)

<!-- Contributors -->

[AlexWheeler]: https://github.com/AlexWheeler
[RomainAlexandre]: https://github.com/RomainAlexandre
[avinoth]: https://github.com/avinoth
[aymeric-ledorze]: https://github.com/aymeric-ledorze
[danielricecodes]: https://github.com/danielricecodes
[jbryant92]: https://github.com/jbryant92
[kevinmcalear]: https://github.com/kevinmcalear
[marycodes2]: https://github.com/marycodes2
[mvz]: https://github.com/mvz
[nedcampion]: https://github.com/nedcampion
[ri4a]: https://github.com/ri4a
[shadydealer]: https://github.com/shadydealer
[thebravoman]: https://github.com/thebravoman
[valeriecodes]: https://github.com/valeriecodes
[wtfspm]: https://github.com/wtfspm

<!-- issues & pull requests -->

[#171]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/171
[#170]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/170
[#164]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/164
[#163]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/163
[#161]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/161
[#160]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/160
[#159]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/159
[#158]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/158
[#157]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/157
[#156]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/156
[#152]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/152
[#150]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/150
[#148]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/148
[#147]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/147
[#146]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/146
[#144]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/144
[#137]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/137
[#136]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/136
[#135]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/135
[#133]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/133
[#131]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/131
[#126]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/126
[#124]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/124
[#123]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/123
[#119]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/119
[#116]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/116
[#114]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/114
[#75]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/75
