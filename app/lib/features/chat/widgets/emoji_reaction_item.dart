import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
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
    final member = ref.watch(chatMemberProvider(userId));
    return member.maybeWhen(
      data: (member) {
        final profile = ref.watch(memberProfileProvider(member));
        return ListTile(
          leading: profile.when(
            data: (data) => ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: userId,
              size: data.hasAvatar() ? 18 : 36,
              avatar: data.getAvatarImage(),
              displayName: data.displayName,
            ),
            loading: () => const Text('loading'),
            error: (e, t) {
              debugPrint('loading avatar failed: $e');
              return ActerAvatar(
                uniqueId: userId,
                displayName: userId,
                mode: DisplayMode.User,
                size: 36,
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
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
