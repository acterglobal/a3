import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmojiReactionItem extends ConsumerWidget {
  final List<String> emojis;
  final String userId;
  final String roomId;
  const EmojiReactionItem({
    super.key,
    required this.emojis,
    required this.userId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: userId, roomId: roomId)),
    );

    return ListTile(
      leading: ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 18)),
      title: Text(avatarInfo.displayName ?? userId),
      subtitle: Text(userId),
      trailing: Wrap(
        children:
            emojis
                .map((emoji) => Text(emoji, style: EmojiConfig.emojiTextStyle))
                .toList(),
      ),
    );
  }
}
