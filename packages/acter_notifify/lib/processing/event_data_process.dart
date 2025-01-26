import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

(String, String?) titleAndBodyForEventDateChange(
    NotificationItem notification) {
  //Generate event date change body
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newEventDate = notification.title();

  String? body = 'by $username to "$newEventDate"';

  //Generate event date change title
  final parent = notification.parent();
  String title;
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = '$parentInfo rescheduled';
  } else {
    title = '$username rescheduled event to "$newEventDate"';
    body = null;
  }

  return (title, body);
}

(String, String?) titleAndBodyForEventRsvpYes(NotificationItem notification) {
  //Generate event rsvp yes title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpYes.emoji} $username will join";

  //Generate event rsvp yes body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}

(String, String?) titleAndBodyForEventRsvpMaybe(NotificationItem notification) {
  //Generate event rsvp maybe title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpMaybe.emoji} $username might join";

  //Generate rsvp maybe body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}

(String, String?) titleAndBodyForEventRsvpNo(NotificationItem notification) {
  //Generate rsvp no title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  String title = "${PushStyles.rsvpNo.emoji} $username will not join";

  //Generate rsvp no body
  String? body;
  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    body = parentInfo;
  }

  return (title, body);
}
