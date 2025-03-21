import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Main container for all activity item widgets
class ActivitySpaceItemContainerWidget extends ConsumerWidget {
  final ActivityObject? activityObject;
  final IconData? actionIcon;
  final String userId;
  final String roomId;
  final Widget? subtitle;
  final int originServerTs;

  const ActivitySpaceItemContainerWidget({
    super.key,
    this.activityObject,
    this.actionIcon,
    required this.userId,
    required this.roomId,
    this.subtitle,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildUserInfoUI(context, ref),
              TimeAgoWidget(originServerTs: originServerTs),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    final memberInfo = ref.watch(
      memberAvatarInfoProvider((roomId: roomId, userId: userId)),
    );
    return ListTile(
      horizontalTitleGap: 10,
      contentPadding: EdgeInsets.zero,
      leading: actionIcon != null
          ? Icon(actionIcon, size: 40)
          : ActerAvatar(options: AvatarOptions(memberInfo, size: 50)),
      title: Text(memberInfo.displayName ?? userId),
      subtitle: subtitle ?? const SizedBox.shrink(),
    );
  }
}
