import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
    final profile = ref
        .watch(memberProfileByInfoProvider((userId: userId, roomId: roomId)));

    return ListTile(
      leading: profile.when(
        data: (data) => ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: data.displayName,
            avatar: data.getAvatarImage(),
          ),
          size: 18,
        ),
        loading: () => Skeletonizer(
          child: ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId),
            size: 24,
          ),
        ),
        error: (e, t) {
          debugPrint('loading avatar failed: $e');
          return ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId, displayName: userId),
            size: 18,
          );
        },
      ),
      title: profile.when(
        data: (data) => Text(data.displayName ?? userId),
        loading: () => Skeletonizer(child: Text(userId)),
        error: (e, s) => Text('loading profile failed: $e'),
      ),
      subtitle: Text(userId),
      trailing: Wrap(
        children: emojis
            .map(
              (emoji) => Text(
                emoji,
                style: EmojiConfig.emojiTextStyle,
              ),
            )
            .toList(),
      ),
    );
  }
}
