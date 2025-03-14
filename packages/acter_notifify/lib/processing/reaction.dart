import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/processing/utils.dart';

import '../model/push_styles.dart';

(String, String?) titleAndBodyForReaction(NotificationItem notification) {
  final emoji = notification.reactionKey() ?? PushStyles.reaction.emoji;
  final suffix = (emoji == PushStyles.reaction.emoji) ? "liked" : "reacted";

  final title = notification.getUserCentricTitlePart(emoji, suffix);

  final parentInfo = notification.parent()?.parentPart();
  return (title, parentInfo);
}
