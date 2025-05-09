import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::widgets::event_date_change');

class ActivityEventDateChangeItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityEventDateChangeItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final activityObject = activity.object();

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
      activityObject: activityObject,
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: getSubtitle(context, stateMsg),
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final content = activity.dateTimeRangeContent();
    if (content == null) {
      _log.severe('failed to get content of date time range change');
      return null;
    }
    switch (content.startChange()) {
      case 'Changed':
        // for now, we can't support the old value
        // because the internal state machine of acter custom message, like pin or task
        final newVal = content.startNewVal()?.toRfc3339() ?? '';
        if (isMe) {
          return lang.activityStartTimeYouChanged(newVal);
        } else {
          return lang.activityStartTimeOtherChanged(senderName, newVal);
        }
      case 'Set':
        final newVal = content.startNewVal()?.toRfc3339() ?? '';
        if (isMe) {
          return lang.activityStartTimeYouSet(newVal);
        } else {
          return lang.activityStartTimeOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.activityStartTimeYouUnset;
        } else {
          return lang.activityStartTimeOtherUnset(senderName);
        }
    }
    switch (content.endChange()) {
      case 'Changed':
        // for now, we can't support the old value
        // because the internal state machine of acter custom message, like pin or task
        final newVal = content.endNewVal()?.toRfc3339() ?? '';
        if (isMe) {
          return lang.activityEndTimeYouChanged(newVal);
        } else {
          return lang.activityEndTimeOtherChanged(senderName, newVal);
        }
      case 'Set':
        final newVal = content.endNewVal()?.toRfc3339() ?? '';
        if (isMe) {
          return lang.activityEndTimeYouSet(newVal);
        } else {
          return lang.activityEndTimeOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.activityEndTimeYouUnset;
        } else {
          return lang.activityEndTimeOtherUnset(senderName);
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
