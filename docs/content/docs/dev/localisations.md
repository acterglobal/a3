# i18n Language Support

## **Acter** have support of internationalisation in the application to support multiple languages. This document gives basic idea of the way it is setup and instruction to maintain it.


##  __==i18n Setup:==__
Reference: <https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#adding-your-own-localized-messages>

* Packages Used:
  `flutter_localizations:
  sdk: flutter
  intl: ^0.18.0 0`
* Configuration:
  `l10n.yaml` file is used at flutter app root folder which contain all the configuration as below.

  ```javascript
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
  ```javascript
  flutter pub get
  ```
  or
  ```javascript
  flutter run
  ```
  then codegen takes place automatically. You should find generated files in
  ```javascript
  ${FLUTTER_PROJECT}/.dart_tool/flutter_gen/gen_l10n
  ```

* Translation:
  [weblate.org](https://weblate.org/en-gb/) is used to manage string translation by taking based of template file.


##  __==Instruction for usage:==__

* Only add/update strings in template file (`app_en.arb`) as [weblate.org](https://weblate.org/en-gb/) is going to take care of translation of other languages
* Avoid manual code formatting or changes in `app_en.arb`. Do changes in template file only when you need to add new string or change English string data.
* Use [Placeholders](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#placeholders-plurals-and-selects) to manage dynamic string support based on the arguments.

  Example

  ```javascript
  "hello": "Hello {userName}",
  ```

* Do not use [plurals-and-selects](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization#placeholders-plurals-and-selects) as it will be to manage translation from [weblate.org](https://weblate.org/en-gb/)

  ```javascript
  //DO NOT USE THIS
  "pronoun": "{gender, select, male{he} female{she} other{they}}",
  
  //USE THIS APPROACH
  "he": "he",
  "she": "she",
  "they": "they",
  ```