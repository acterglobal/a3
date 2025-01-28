import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data.dart';

(String, String?) titleAndBodyForObjectTitleChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newTitle = notification.title();

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final title = '$parentInfo renamed';
    final body = 'by $username to "$newTitle"';
    return (title, body);
  } else {
    final title = '$username renamed title to "$newTitle"';
    return (title, null);
  }
}
