import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectDescriptionChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newDescription = notification.title();

  final content = '$username updated description: "$newDescription"';

  final title = notification.parent()?.getObjectCentricTitlePart('changed');
  if (title != null) {
    return (title, content);
  } else {
    return (content, null);
  }
}
