import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/parent_data.dart';

(String, String?) titleAndBodyForEventDateChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newEventDate = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final title = '$parentInfo rescheduled';
    final body = 'by $username to "$newEventDate"';
    return (title, body);
  } else {
    final title = '$username rescheduled event to "$newEventDate"';
    return (title, null);
  }
}

(String, String?) titleAndBodyForEventRsvpYes(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpYes.emoji} $username will join";

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    return (title, parentInfo);
  }

  return (title, null);
}

(String, String?) titleAndBodyForEventRsvpMaybe(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpMaybe.emoji} $username might join";

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    return (title, parentInfo);
  }

  return (title, null);
}

(String, String?) titleAndBodyForEventRsvpNo(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpNo.emoji} $username will not join";

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    return (title, parentInfo);
  }

  return (title, null);
}
