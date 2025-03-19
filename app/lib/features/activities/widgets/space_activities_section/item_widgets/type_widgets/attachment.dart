import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityAttachmentItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityAttachmentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final activityObject = activity.object();
    final name = activity.name();
    final subType = activity.subTypeStr();

    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.paperclip,
      actionTitle: L10n.of(context).addedAttachmentOn,
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: Text(
        '$subType : $name',
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      originServerTs: activity.originServerTs(),
    );
  }
}
