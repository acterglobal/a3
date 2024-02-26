import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:logging/logging.dart';

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
    final memberProfile = ref
        .watch(memberProfileByInfoProvider((userId: userId, roomId: roomId)));
    return memberProfile.when(
      data: (profile) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
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
