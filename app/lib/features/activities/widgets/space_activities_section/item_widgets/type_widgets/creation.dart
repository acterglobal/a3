import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityCreationItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityCreationItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.add_circle_outline,
      actionTitle: L10n.of(context).creation,
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
