import 'package:acter/features/activities/widgets/space_activities/item_widgets/activity_item_container_widgets.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/model/push_styles.dart';
import 'package:flutter/material.dart';

class ActivityReactionItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReactionItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ActivityUserCentricItemContainerWidget(
      actionTitle: '${PushStyles.reaction.emoji} Reacted on',
      actionObjectInfo: getObjectInfo(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: '',
      originServerTs: activity.originServerTs(),
    );
  }

  String getObjectInfo() {
    final objectEmoji = activity.object()?.emoji();
    final objectTitle = switch (activity.object()?.typeStr()) {
      'news' => 'Boost',
      'stories' => 'Story',
      _ => activity.object()?.title(),
    };
    return '$objectEmoji $objectTitle';
  }
}
