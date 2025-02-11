import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/acter_notifify.dart';

(String, String?) titleAndBodyForObjectDescriptionChange(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final newDescription = notification.title();

  final content = locales.objectDescriptionChangeBody(username, newDescription);

  final parent = notification.parent();
  if (parent != null) {
    final title = locales.objectDescriptionChangeTitle(parent);
    return (title, content);
  } else {
    return (content, null);
  }
}
