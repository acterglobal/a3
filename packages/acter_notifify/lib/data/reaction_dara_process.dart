import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/data/parent_data_process.dart';

import 'data_contants.dart';

(String, String?) titleAndBodyForReaction(NotificationItem notification) {
  final parent = notification.parent();
  final reaction = notification.reactionKey() ?? PushStyles.reaction.emoji;
  String title = '"$reaction"';
  if (parent != null) {
    final parentInfo = parentPart(parent);
    title = "$title to $parentInfo";
  }

  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();

  return (title, username);
}
