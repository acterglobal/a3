import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::activities::widgets::room_topic_change');

class ActivityRoomTopicItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityRoomTopicItemWidget({super.key, required this.activity});

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

    final subTitle = activity.roomTopic() ?? '';
    return ActivitySpaceProfileChangeContainerWidget(
      leadingWidget: Icon(PhosphorIconsRegular.pencilSimpleLine, size: 40),
      titleText: stateMsg ?? '',
      subtitleWidget: getSubtitle(context, subTitle),
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final content = activity.roomTopicContent();
    if (content == null) {
      _log.severe('failed to get content of room topic change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomTopicYouChanged(newVal, oldVal);
        } else {
          return lang.roomStateRoomTopicOtherChanged(
            senderName,
            newVal,
            oldVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomTopicYouSet(newVal);
        } else {
          return lang.roomStateRoomTopicOtherSet(senderName, newVal);
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
