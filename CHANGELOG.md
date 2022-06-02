# Changelog

## [1.1.2]

* Contributions from [Marvin Möltgen](https://github.com/M123-dev)
  * fix [#8](https://github.com/Floating-Dartists/matomo-tracker/issues/8): Send country code only in combination with auth_token

## [1.1.1]

* Contributions from [Marvin Möltgen](https://github.com/M123-dev)
  * fix: Now exporting the `Visitor` class [#6](https://github.com/Floating-Dartists/matomo-tracker/pull/6)

## [1.1.0]

* Contributions from [Marvin Möltgen](https://github.com/M123-dev)
    * feat: Allow to see the opt out status [#5](https://github.com/Floating-Dartists/matomo-tracker/pull/5)
    * feat: Allow tracking of outlinks [#4](https://github.com/Floating-Dartists/matomo-tracker/pull/4)
    * feat: Send country code [#2](https://github.com/Floating-Dartists/matomo-tracker/pull/2)
    * feat: Allow search tracking [#3](https://github.com/Floating-Dartists/matomo-tracker/pull/3)

## [1.0.3+1]

* Updated README with new logo and link to Matomo Integrations page

## [1.0.3]

* Added `path` property to `TraceableClientMixin`
* Improved documentation

## [1.0.2]

* Fixed default `TraceableClientMixin.widgetId`, now `null` and you will have to set it manually with a length of 6 characters
* Migrated example app to null-safety

## [1.0.1+2]

* Fixed README.md typo
* Improved documentation

## [1.0.1+1]

* Updated README with pub version & Matomo Tracking documentation link

## [1.0.1]

* Fixed `visitorId` not being set for future visits

## [1.0.0]

* Initial release of matomo-tracker
