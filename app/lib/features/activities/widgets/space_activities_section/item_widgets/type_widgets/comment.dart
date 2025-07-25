import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/activities/actions/activity_item_click_action.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/containers/activity_bigger_visual_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActivityCommentItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityCommentItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityObject = activity.object();
    final originServerTs = activity.originServerTs();
    return ActivityBiggerVisualContainerWidget(
      onTap: () => onTapActivityItem(context, activityObject),
      activityObject: activityObject,
      actionIcon: PhosphorIconsRegular.chatCenteredDots,
      actionIconBgColor: Colors.amber.shade800,
      actionIconColor: Colors.white,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      actionTitle: L10n.of(context).commentedOn,
      target: getActivityObjectTitle(context),
      subtitle: Text(
        activity.msgContent()?.body() ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colorScheme.surfaceTint),
      ),
      originServerTs: originServerTs,
    );
  }

   String getActivityObjectTitle(BuildContext context) {
    return switch (activity.object()?.typeStr()) {
      'news' => L10n.of(context).boost,
      'story' => L10n.of(context).story,
      _ => activity.object()?.title() ?? '',
    };
  }
  
}
