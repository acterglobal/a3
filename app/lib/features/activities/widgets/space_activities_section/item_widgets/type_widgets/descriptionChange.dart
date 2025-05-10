import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityDescriptionChangeItemWidget extends StatelessWidget {
  final Activity activity;
  const ActivityDescriptionChangeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return ActivityUserCentricItemContainerWidget(
      actionIcon: PhosphorIconsRegular.pencilLine,
      actionTitle: lang.updatedDescription,
      activityObject: activity.object(),
      subtitle: Text(
        '${lang.newDescription}: ${activity.descriptionContent()?.newVal().toString()}',
        style: Theme.of(context).textTheme.labelMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
    );
  }
}
