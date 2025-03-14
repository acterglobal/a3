import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectOtherChanges(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final title = notification.parent()?.getObjectCentricTitlePart('updated');
  if (title != null) {
    final body = 'by $username';
    return (title, body);
  } else {
    final title = '$username updated object';
    return (title, null);
  }
}
