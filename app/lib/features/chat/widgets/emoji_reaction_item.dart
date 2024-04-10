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
    final profile =
        ref.watch(roomMemberProvider((userId: userId, roomId: roomId)));

    return ListTile(
      leading: profile.when(
        data: (data) => ActerAvatar(
          mode: DisplayMode.DM,
          avatarInfo: AvatarInfo(
            uniqueId: userId,
            displayName: data.profile.displayName,
            avatar: data.profile.getAvatarImage(),
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
        error: (e, s) {
          _log.severe('loading avatar failed', e, s);
          return ActerAvatar(
            mode: DisplayMode.DM,
            avatarInfo: AvatarInfo(uniqueId: userId, displayName: userId),
            size: 18,
          );
        },
      ),
      title: profile.when(
        data: (data) => Text(data.profile.displayName ?? userId),
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
