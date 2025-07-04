import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityCreationItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityCreationItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityObject = activity.object();
    return ActivityIndividualActionContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      actionIcon: Icons.add,
      actionIconBgColor: Colors.deepPurple,
      actionIconColor: Colors.white,
      actionTitle:
          '${L10n.of(context).creation} ${activityObject?.typeStr() ?? ''}',
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      target: activityObject?.title() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
