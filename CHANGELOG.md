## [2.1.0] - 13/05/2023
* New Functions: `captureFromLongWidget` and `longWidgetToUiImage`. Calculates widgets size and captures whole widget at once.
* BREAKING CHANGE: add minimum flutter version constraint. so if your project is below flutter 3.10, Please consider using version 1.3.0
## [2.0.0] - 13/05/2023
* BREAKING CHANGE: supports flutter version >=3.10 only. 
* Migrate to `FlutterView` from `ui.window` @Mayb3Nots
## [1.3.0] - 27/12/2022
* Fix disposing widgets after capturing in widgetToUiImage function @Lan-tb 
## [1.2.3] - 15/07/2021
* Support Inheriting Theme for Invisible Widget

## [1.2.2] - 14/07/2021
* Add pixelRatio to captureFromWidget @hashirshoaeb
* Fix assertion issue

## [1.2.1] - 13/06/2021
* Removal of compilation warning @yanivshaked

## [1.2.0] - 13/06/2021
* Add support for invisible widget capture

## [1.0.0-nullsafety.0] - 10/02/2021
* Add nullsafety

## [0.3.0] - 10/02/2021
* breaking change capture method returns Uint8List instead of File.
* support for web and windows
* Add captureAndSave method.

## [0.2.0] - 10/06/2020
* Add captureAsUiImage method

## [0.1.1] - 11/05/2019
* 20 Millisecond delay has been added. See issue https://github.com/flutter/flutter/issues/22308
* Example app can now save images directly to Gallery (using https://github.com/hui-z/image_gallery_saver)

## [0.1.0] - 09/05/2019
* changed path_provider version to ^1.1.0

## [0.0.2] - 16/02/2019
* added support for older versions of path provider

## [0.0.1] - 12/02/2019

* initial release.
