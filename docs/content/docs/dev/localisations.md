+++
title = "Localisation"
weight = 10
template = "docs/page.html"
[extra]
toc = true
top = false
+++
title = "Localisation"
# i18n Language Support

## **Acter** has support for internationalization in the application to support multiple languages. This document presents the basic idea of the way it is setup and instruction to maintain it.


## i18n Setup
Reference: <https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#adding-your-own-localized-messages>

* Packages Used:
  `flutter_localizations:
  sdk: flutter
  intl: ^0.18.0 0`
* Configuration:
  `l10n.yaml` file is used at flutter `app/` folder which contain all the configuration as below.

  ```
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: l10n.dart
  output-class: L10n
  preferred-supported-locales: ["en"]
  nullable-getter: false
  ```

* Template File:
  `a3/app/lib/l10n/app_en.arb` file which is containing all the English language strings is used as template file.
* Language specific dart files:
  When we do
  ```
  flutter pub get
  ```
  
  or

  ```
  flutter run
  ```
  then codegen takes place automatically. You should find generated files in
  ```
  ${FLUTTER_PROJECT}/.dart_tool/flutter_gen/gen_l10n
  ```

* Translation:
  [weblate.org](https://weblate.org/en-gb/) is used to manage string translation by taking based of template file.


##  Instruction for usage

* Only add/update strings in template file (`app_en.arb`) as [weblate.org](https://weblate.org/en-gb/) is going to take care of all translations (including the english strings)
* Avoid manual code formatting or changes in `app_en.arb`. Do changes in template file only when you need to add new string or change keys.
* Use [Placeholders](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#placeholders-plurals-and-selects) to manage dynamic string support based on the arguments.

  Example

  ```
  "hello": "Hello {userName}",
  ```

* Do not use [selects](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#placeholders-plurals-and-selects) for otherwise similar strings but use distinctive strings
```
//DO NOT USE THIS
"loading": "{objects, select, tasks{Tasks} events{Events } other{}}",

//USE THIS APPROACH
"loadingTasks": "Loading Tasks",
"loadingEvents": "Loading Events",
```