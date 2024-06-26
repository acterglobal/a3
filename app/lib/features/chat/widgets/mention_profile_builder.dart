import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MentionProfileBuilder extends ConsumerWidget {
  final String roomId;
  final String authorId;

  const MentionProfileBuilder({
    super.key,
    required this.roomId,
    required this.authorId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mentionProfile =
        ref.watch(memberAvatarInfoProvider((userId: authorId, roomId: roomId)));
    return ActerAvatar(
      options: AvatarOptions.DM(
        mentionProfile,
        size: 18,
      ),
    );
  }
}
