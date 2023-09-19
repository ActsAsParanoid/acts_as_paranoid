# CHANGELOG

Notable changes to this project will be documented in this file.

## 0.8.1

* Officially support Ruby 3.1 ([#268], by [Matijs van Zuijlen][mvz])
* Fix association building for `belongs_to` with `:with_deleted` option ([#277], by [Matijs van Zuijlen][mvz])

## 0.8.0

* Do not set `paranoid_value` when destroying fully ([#238], by [Aymeric Le Dorze][aymeric-ledorze])
* Make helper methods for dependent associations private ([#239], by [Matijs van Zuijlen][mvz])
* Raise ActiveRecord::RecordNotDestroyed if destroy returns false ([#240], by [Hao Liu][leomayleomay])
* Make unscoping by `with_deleted` less blunt ([#241], by [Matijs van Zuijlen][mvz])
* Drop support for Ruby 2.4 and 2.5 ([#243] and [#245] by [Matijs van Zuijlen][mvz])
* Remove deprecated methods ([#244] by [Matijs van Zuijlen][mvz])
* Remove test files from the gem ([#261] by [Matijs van Zuijlen][mvz])
* Add support for Rails 7 ([#262] by [Vederis Leunardus][cloudsbird])

## 0.7.3

## Improvements

* Fix deletion time scopes ([#212] by [Matijs van Zuijlen][mvz])
* Reload `has_one` associations after dependent recovery ([#214],
  by [Matijs van Zuijlen][mvz])
* Make dependent recovery work when parent is non-optional ([#227],
  by [Matijs van Zuijlen][mvz])
* Avoid querying nil `belongs_to` associations when recovering ([#219],
  by [Matijs van Zuijlen][mvz])
* On relations, deprecate `destroy!` in favour of `destroy_fully!` ([#222],
  by [Matijs van Zuijlen][mvz])
* Deprecate the undocumented `:recovery_value` setting. Calculate the correct
  value instead. ([#220], by [Matijs van Zuijlen][mvz])

## Developer experience

* Log ActiveRecord activity to a visible log during tests ([#218],
  by [Matijs van Zuijlen][mvz])

## 0.7.2

* Do not set boolean column to NULL on recovery if nulls are not allowed
  ([#193], by [Shodai Suzuki][soartec-lab])
* Add a CONTRIBUTING.md file ([#207], by [Matijs van Zuijlen][mvz])

## 0.7.1

* Support Rails 6.1 ([#191], by [Matijs van Zuijlen][mvz])
* Support `belongs_to` with both `:touch` and `:counter_cache` options ([#208],
  by [Matijs van Zuijlen][mvz] with [Paul Druziak][pauldruziak])
* Support Ruby 3.0 ([#209], by [Matijs van Zuijlen][mvz])

## 0.7.0

### Breaking changes

* Support Rails 5.2+ only ([#126], by [Daniel Rice][danielricecodes])
* Update set of supported rubies to 2.4-2.7 ([#144], [#173] by [Matijs van Zuijlen][mvz])

### Improvements

* Handle `with_deleted` association option as a scope ([#147], by [Matijs van Zuijlen][mvz])
* Simplify validation override ([#158], by [Matijs van Zuijlen][mvz])
* Use correct unscope syntax so unscope works on Rails Edge ([#160],
  by [Matijs van Zuijlen][mvz])
* Fix ruby 2.7 keyword argument deprecation warning ([#161], by [Jon Riddle][wtfspm])

### Documentation

* Document save after destroy behavior ([#146], by [Matijs van Zuijlen][mvz])
* Update version number instructions for installing gem ([#164],
  by [Kevin McAlear][kevinmcalear])
* Add example with `destroyed_fully?` and `deleted_fully?` to the readme ([#170],
  by [Kiril Mitov][thebravoman])

### Internal

* Improve code quality using RuboCop ([#148], [#152], [#159], [#163], [#171] and [#173],
  by [Matijs van Zuijlen][mvz])
* Measure code coverage using SimpleCov ([#150] and [#175] by [Matijs van Zuijlen][mvz])
* Silence warnings emitted during tests ([#156], by [Matijs van Zuijlen][mvz])
* Make rake tasks more robust and intuitive ([#157], by [Matijs van Zuijlen][mvz])

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
[cloudsbird]: https://github.com/cloudsbird
[aymeric-ledorze]: https://github.com/aymeric-ledorze
[danielricecodes]: https://github.com/danielricecodes
[jbryant92]: https://github.com/jbryant92
[kevinmcalear]: https://github.com/kevinmcalear
[leomayleomay]: https://github.com/leomayleomay
[marycodes2]: https://github.com/marycodes2
[mvz]: https://github.com/mvz
[nedcampion]: https://github.com/nedcampion
[ri4a]: https://github.com/ri4a
[pauldruziak]: https://github.com/pauldruziak
[shadydealer]: https://github.com/shadydealer
[soartec-lab]: https://github.com/soartec-lab
[thebravoman]: https://github.com/thebravoman
[valeriecodes]: https://github.com/valeriecodes
[wtfspm]: https://github.com/wtfspm

<!-- issues & pull requests -->

[#277]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/277
[#268]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/268
[#262]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/262
[#261]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/261
[#245]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/245
[#244]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/244
[#243]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/243
[#241]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/241
[#240]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/240
[#239]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/239
[#238]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/238
[#227]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/227
[#222]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/222
[#220]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/220
[#219]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/219
[#218]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/218
[#214]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/214
[#212]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/212
[#209]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/209
[#208]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/208
[#207]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/207
[#193]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/193
[#191]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/191
[#175]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/175
[#173]: https://github.com/ActsAsParanoid/acts_as_paranoid/pull/173
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
