import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

import '../model/push_styles.dart';

(String, String?) titleAndBodyForReaction(NotificationItem notification) {
  final emoji = notification.reactionKey() ?? PushStyles.reaction.emoji;
  final suffix = (emoji == PushStyles.reaction.emoji) ? "liked" : "reacted";

  final title = getUserCentricTitlePart(notification, emoji, suffix);

  final parent = notification.parent();
  if (parent != null) {
    final parentInfo = parentPart(parent);
    final body = parentInfo;
    return (title, body);
  }

  return (title, null);
}
