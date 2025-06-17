import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_social_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityReactionItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReactionItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ActivitySocialContainerWidget(
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      icon: Icons.favorite,
      iconColor: Colors.red.shade400,
      actionTitle: L10n.of(context).reactedOn,
      originServerTs: activity.originServerTs(),
    );
  }
}
