import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ActerNotififyL10nEn extends ActerNotififyL10n {
  ActerNotififyL10nEn([String locale = 'en']) : super(locale);

  @override
  String objectTitleChangeBody(Object newTitle, Object username) {
    return 'by \$$username to \"\$$newTitle\"';
  }
}
