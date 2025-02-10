import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ActerNotififyL10nEn extends ActerNotififyL10n {
  ActerNotififyL10nEn([String locale = 'en']) : super(locale);

  @override
  String objectTitleChangeTitle(Object parentInfo) {
    return '$parentInfo renamed';
  }

  @override
  String objectTitleChangeTitleNoParent(Object username, Object newTitle) {
    return '$username renamed title to \"$newTitle\"';
  }

  @override
  String objectTitleChangeBody(Object username, Object newTitle) {
    return 'by $username to \"$newTitle\"';
  }
}
