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
    return ActivityIndividualActionContainerWidget(
      actionIcon: Icons.add,
      actionIconBgColor: Colors.deepPurple,
      actionIconColor: Colors.white,
      actionTitle:
          '${L10n.of(context).creation} ${activity.object()?.typeStr() ?? ''}',
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      target: activity.object()?.title() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
