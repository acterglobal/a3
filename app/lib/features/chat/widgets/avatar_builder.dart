import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvatarBuilder extends ConsumerWidget {
  final String userId;
  final String roomId;

  const AvatarBuilder({
    Key? key,
    required this.userId,
    required this.roomId,
  }) : super(key: key);

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
        debugPrint('ERROR loading avatar due to $e');
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId, displayName: userId),
            size: 14,
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }
}
