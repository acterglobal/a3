import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectRedaction(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final spaceName = notification.title();

  final title = notification.parent()?.getObjectCentricTitlePart('removed');
  if (title != null) {
    final body = 'by $username from "$spaceName"';
    return (title, body);
  } else {
    final title = '$username removed object from "$spaceName"';
    return (title, null);
  }
}
