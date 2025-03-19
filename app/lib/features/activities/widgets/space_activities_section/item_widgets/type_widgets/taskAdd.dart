import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class ActivityTaskAddItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityTaskAddItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final name = activity.name();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.add_circle_outline,
      actionTitle: L10n.of(context).created,
      subtitle: Text(
        '${L10n.of(context).taskLabel} : $name',
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
