import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserChip extends ConsumerWidget {
  final VisualDensity? visualDensity;
  final String roomId;
  final String memberId;

  const UserChip({
    super.key,
    required this.roomId,
    required this.memberId,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberInfo =
        ref.watch(roomMemberProvider((roomId: roomId, userId: memberId)));
    return memberInfo.when(
      data: (profile) => Chip(
        visualDensity: visualDensity,
        avatar: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: memberId,
            displayName: profile.displayName,
            avatar: profile.getAvatarImage(),
          ),
          size: 24,
        ),
        label: Text(profile.displayName ?? memberId),
      ),
      error: (e, s) => Chip(label: Text('Error loading $memberId: $e')),
      loading: () => Skeletonizer(
        child: Chip(
          visualDensity: visualDensity,
          avatar: const Icon(Atlas.user_thin),
          label: Text(memberId),
        ),
      ),
    );
  }
}
