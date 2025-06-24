import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_individual_action_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityOtherChangesItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityOtherChangesItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActivityIndividualActionContainerWidget(
      actionIcon: PhosphorIconsRegular.pencilLine,
      actionTitle:
          '${L10n.of(context).updated} ${activity.object()?.typeStr() ?? ''}',
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      target: activity.object()?.title() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
