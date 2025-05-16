import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_item_container_widgets.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::description_change');

class ActivityDescriptionChangeItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityDescriptionChangeItemWidget({
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
      actionIcon: PhosphorIconsRegular.pencilLine,
      actionTitle: lang.updatedDescription,
      activityObject: activity.object(),
      userId: activity.senderIdStr(),
      roomId: activity.roomIdStr(),
      subtitle: getSubtitle(context, stateMsg),
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final content = activity.descriptionContent();
    if (content == null) {
      _log.severe('failed to get content of description change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        // for now, we can't support the old value
        // because the internal state machine is not ready about acter custom message, like pin or task
        final newVal = content.newVal() ?? '';
        if (isMe) {
          return lang.activityDescriptionYouChanged(newVal);
        } else {
          return lang.activityDescriptionOtherChanged(senderName, newVal);
        }
      case 'Set':
        final newVal = content.newVal() ?? '';
        if (isMe) {
          return lang.activityDescriptionYouSet(newVal);
        } else {
          return lang.activityDescriptionOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.activityDescriptionYouUnset;
        } else {
          return lang.activityDescriptionOtherUnset(senderName);
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
