import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

(String, String?) titleAndBodyForObjectInvitation(
    NotificationItem notification) {
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  final objectTitle = notification.parent()?.parentPart();
  if (notification.mentionsYou()) {
    return ("📨 $username invited you", objectTitle);
  } else {
    final whom = notification.whom();
    late String title;
    if (whom.length == 1) {
      final first = whom.first.toDartString();
      title = "📨 $username invited $first";
    } else {
      title = "📨 $username invited ${whom.length} people";
    }
    return (objectTitle != null) ? (objectTitle, title) : (title, null);
  }
}
