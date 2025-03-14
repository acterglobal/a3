import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityReactionItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityReactionItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.heart,
      actionIconColor: Colors.red.shade400,
      actionTitle: L10n.of(context).reactedOn,
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
