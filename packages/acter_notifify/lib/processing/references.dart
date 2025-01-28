import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForReferences(NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final referencesObject = notification.title();

  final content = "$username linked $referencesObject";

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    return (parentInfo, content);
  } else {
    return (content, null);
  }
}
