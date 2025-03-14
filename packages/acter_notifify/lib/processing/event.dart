import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForEventDateChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  // FIXME: use actual date given
  final newEventDate = notification.title();

  final title = notification.parent()?.getObjectCentricTitlePart('rescheduled');
  if (title != null) {
    final body = 'by $username to "$newEventDate"';
    return (title, body);
  } else {
    final title = '$username rescheduled event to "$newEventDate"';
    return (title, null);
  }
}

(String, String?) titleAndBodyForEventRsvpYes(NotificationItem notification) {
  final emoji = PushStyles.rsvpYes.emoji;
  final title = notification.getUserCentricTitlePart(emoji, 'will join');

  final parentInfo = notification.parent()?.parentPart();
  if (parentInfo != null) {
    return (parentInfo, title);
  }

  return (title, null);
}

(String, String?) titleAndBodyForEventRsvpMaybe(NotificationItem notification) {
  final emoji = PushStyles.rsvpMaybe.emoji;
  final title = notification.getUserCentricTitlePart(emoji, 'might join');

  final parentInfo = notification.parent()?.parentPart();
  if (parentInfo != null) {
    return (parentInfo, title);
  }

  return (title, null);
}

(String, String?) titleAndBodyForEventRsvpNo(NotificationItem notification) {
  final emoji = PushStyles.rsvpNo.emoji;
  final title = notification.getUserCentricTitlePart(emoji, 'will not join');

  final parentInfo = notification.parent()?.parentPart();
  if (parentInfo != null) {
    return (parentInfo, title);
  }

  return (title, null);
}
