import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_space_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class ActivityRoomAvatarItemWidget extends ConsumerWidget {
  final Activity activity;
  const ActivityRoomAvatarItemWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(roomAvatarInfoProvider(activity.roomIdStr()));
     final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: activity.roomIdStr(), userId: activity.senderIdStr())),
    );
    return ActivitySpaceProfileChangeContainerWidget(
      leadingWidget: ActerAvatar(options: AvatarOptions(avatarInfo, size: 50)),
      titleText: L10n.of(context).spaceAvatarUpdate(memberInfo.displayName ?? activity.senderIdStr()),
      originServerTs: activity.originServerTs(),
    );
  }
}
