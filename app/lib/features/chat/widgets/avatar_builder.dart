import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::avatar_builder');

class AvatarBuilder extends ConsumerWidget {
  final String roomId;
  final String userId;

  const AvatarBuilder({
    super.key,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberProfile =
        ref.watch(roomMemberProvider((userId: userId, roomId: roomId)));
    return memberProfile.when(
      data: (data) {
        final profile = data.profile;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            onAvatarTap: () async {
              // ignore: use_build_context_synchronously
              showMemberInfoDrawer(
                context: context,
                roomId: roomId,
                memberId: userId,
              );
            },
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(
              uniqueId: userId,
              displayName: profile.displayName ?? userId,
              avatar: profile.getAvatarImage(),
            ),
            size: 14,
          ),
        );
      },
      error: (e, st) {
        _log.severe('Error loading avatar', e, st);
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId, displayName: userId),
            size: 14,
          ),
        );
      },
      loading: () => Skeletonizer(
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId, displayName: userId),
            size: 14,
          ),
        ),
      ),
    );
  }
}
