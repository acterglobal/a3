import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::widgets::task_due_date_change');

class ActivityTaskDueDateChangedItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityTaskDueDateChangedItemWidget({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    final roomId = activity.roomIdStr();
    final senderId = activity.senderIdStr();
    final myId = ref.watch(myUserIdStrProvider);
    final firstName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull;
    final senderName = firstName ?? simplifyUserId(senderId) ?? senderId;

    final stateMsg = getMessage(lang, myId == senderId, senderName);

    return ActivityUserCentricItemContainerWidget(
      actionIcon: Icons.access_time,
      actionTitle: L10n.of(context).rescheduled,
      actionIconColor: Colors.grey.shade400,
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      originServerTs: activity.originServerTs(),
      subtitle: getSubtitle(context, stateMsg),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final content = activity.dateContent();
    if (content == null) {
      _log.severe('failed to get content of date change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        // for now, we can't support the old value
        // because the internal state machine of acter custom message, like pin or task
        final newVal = content.newVal() ?? '';
        if (isMe) {
          return lang.activityDueDateYouChanged(newVal);
        } else {
          return lang.activityDueDateOtherChanged(senderName, newVal);
        }
      case 'Set':
        final newVal = content.newVal() ?? '';
        if (isMe) {
          return lang.activityDueDateYouSet(newVal);
        } else {
          return lang.activityDueDateOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.activityDueDateYouUnset;
        } else {
          return lang.activityDueDateOtherUnset(senderName);
        }
    }
    return null;
  }

  Widget? getSubtitle(BuildContext context, String? stateMsg) {
    if (stateMsg == null) return null;
    return Text(
      stateMsg,
      style: Theme.of(context).textTheme.labelMedium,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
