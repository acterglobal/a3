import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::activities::widgets::room_avatar_change');

class ActivityRoomAvatarItemWidget extends ConsumerWidget {
  final Activity activity;

  const ActivityRoomAvatarItemWidget({super.key, required this.activity});

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

    final avatarInfo = ref.watch(roomAvatarInfoProvider(activity.roomIdStr()));
    return ActivitySpaceProfileChangeContainerWidget(
      leadingWidget: ActerAvatar(options: AvatarOptions(avatarInfo, size: 50)),
      titleText: stateMsg ?? '',
      originServerTs: activity.originServerTs(),
    );
  }

  String? getMessage(L10n lang, bool isMe, String senderName) {
    final content = activity.roomAvatarContent();
    if (content == null) {
      _log.severe('failed to get content of room avatar change');
      return null;
    }
    switch (content.urlChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouChanged;
        } else {
          return lang.roomStateRoomAvatarUrlOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouSet;
        } else {
          return lang.roomStateRoomAvatarUrlOtherSet(senderName);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouUnset;
        } else {
          return lang.roomStateRoomAvatarUrlOtherUnset(senderName);
        }
    }
    return null;
  }
}
