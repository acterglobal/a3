import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::chat::emoji_reaction_item');

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
    final memberAvatarInfo =
        ref.watch(roomMemberProvider((userId: userId, roomId: roomId)));

    return ListTile(
      leading: memberAvatarInfo.when(
        data: (data) => ActerAvatar(
          options: AvatarOptions.DM(
            AvatarInfo(
              uniqueId: userId,
              displayName: data.avatarInfo.displayName,
              avatar: data.avatarInfo.avatar,
            ),
            size: 18,
          ),
        ),
        loading: () => Skeletonizer(
          child: ActerAvatar(
            options: AvatarOptions.DM(
              AvatarInfo(uniqueId: userId),
              size: 24,
            ),
          ),
        ),
        error: (e, s) {
          _log.severe('loading avatar failed', e, s);
          return ActerAvatar(
            options: AvatarOptions(
              AvatarInfo(uniqueId: userId, displayName: userId),
              size: 18,
            ),
          );
        },
      ),
      title: memberAvatarInfo.when(
        data: (data) => Text(data.avatarInfo.displayName ?? userId),
        loading: () => Skeletonizer(child: Text(userId)),
        error: (e, s) => Text(L10n.of(context).loadingProfileFailed(e)),
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
