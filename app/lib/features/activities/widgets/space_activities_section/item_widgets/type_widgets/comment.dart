import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityCommentItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityCommentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.chatCenteredDots,
      actionTitle: L10n.of(context).commentedOn,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: activity.msgContent()?.body() ?? '',
      originServerTs: activity.originServerTs(),
    );
  }
}
