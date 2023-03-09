+++
title = "Localisation"

weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++

Acter app is supported with flutter localizations and it is already setup and defined in `pubspec.yaml`.

## Add new locale in the application

1. Firstly go the `l10.dart` file and add the locale you want to support in the application.

```
class ApplicationLocalizations {
  static final supportedLocales = [const Locale('en'), const Locale('de')];
}
```

2. Create an `.arb` extension file in **l10** directory. Here you can add your locale strings with key-value pairs as in JSON format. For example

```
{
    "language": "English",
    "all": "all",
    "noMessages": "No Conversations yet",
    "loading": "loading",
}
```

3. Save the file and rebuild the project. Verify that the localization file has been successfully generated in your project build files. The generated path from root directory is `dart_tool/flutter_gen/app_localizations_en.dart`, in case the locale is english.

## Add new localized text in the application

1. Navigate to `app_en.arb` file.
2. Add a new key-value pair containing the string. For Example:

```
{
    "language": "English",
    "all": "all",
    "noMessages": "No Conversations yet",
    "loading": "loading",
    "news": "news"
}
```

3. To support this text in **deutsch**. We also need to update `app_de.arb`.

```
{
    "language": "Deutsch",
    "all": "alle",
    "noMessages": "Noch keine Gespräche",
    "loading": "Wird geladen",
    "news": "Nachrichten",
}
```

4. Save the file and rebuild the project. You can use your new localized string in your dart files.

```
Text(AppLocalizations.of(context)!.news);
```
