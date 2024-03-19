import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::mention_profile_builder');

class MentionProfileBuilder extends ConsumerWidget {
  final String roomId;
  final String authorId;
  final String title;

  const MentionProfileBuilder({
    super.key,
    required this.roomId,
    required this.authorId,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionProfile = ref
        .watch(memberProfileByInfoProvider((userId: authorId, roomId: roomId)));
    return mentionProfile.when(
      data: (profile) => ActerAvatar(
        mode: DisplayMode.DM,
        avatarInfo: AvatarInfo(
          uniqueId: authorId,
          avatar: profile.getAvatarImage(),
          displayName: title,
        ),
        size: 18,
      ),
      error: (e, st) {
        _log.severe('ERROR loading avatar', e, st);
        return ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: authorId, displayName: title),
          size: 18,
        );
      },
      loading: () => Skeletonizer(
        child: ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(uniqueId: authorId),
          size: 18,
        ),
      ),
    );
  }
}
