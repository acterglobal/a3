import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmojiReactionItem extends ConsumerWidget {
  final List<String> emojis;
  final String userId;
  const EmojiReactionItem({
    Key? key,
    required this.emojis,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(memberProfileByIdProvider(userId));

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
        loading: () => const Text('loading'),
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
        loading: () => Text(userId),
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
