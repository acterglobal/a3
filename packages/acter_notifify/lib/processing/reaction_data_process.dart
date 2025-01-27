import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/parent_data_process.dart';

import '../model/push_styles.dart';

(String, String?) titleAndBodyForReaction(NotificationItem notification) {
  //Generate reaction title
  final sender = notification.sender();
  final username = sender.displayName() ?? sender.userId();
  final reaction = notification.reactionKey() ?? PushStyles.reaction.emoji;

  late String title;
  if (reaction == PushStyles.reaction.emoji) {
    title = "$reaction $username liked";
  } else {
    title = "$reaction $username reacted";
  }

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final body = parentInfo;
    return (title, body);
  }

  return (title, null);
}
