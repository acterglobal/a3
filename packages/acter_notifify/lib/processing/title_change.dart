import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectTitleChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newTitle = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final title = getObjectCentricTitlePart(parent, 'renamed');
    final body = 'by $username to "$newTitle"';
    return (title, body);
  } else {
    final title = '$username renamed title to "$newTitle"';
    return (title, null);
  }
}
