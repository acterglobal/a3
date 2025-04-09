import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingIndicator extends ConsumerWidget {
  final String roomId;

  const TypingIndicator({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    //Get the typing users and the typing text
    final typingUsers = _getTypingUsers(ref);
    final typingText = _getTypingText(context, ref, typingUsers);
    if (typingText.isEmpty) return const SizedBox.shrink();

    //Animated circles
    final animatedCircles = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AnimatedCircles(theme: theme.typingIndicatorTheme),
    );

    //If it's a DM, return the animated circles
    final isDM = _getIsDM(ref);
    if (isDM == true) return animatedCircles;

    //Show the typing text with the animated circles
    return Row(
      children: [
        Text(
          typingText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        animatedCircles,
      ],
    );
  }

  String _getTypingText(BuildContext context, ref, List<User> typingUsers) {
    final lang = L10n.of(context);

    //If there are no typing users, return an empty string
    if (typingUsers.isEmpty) return '';

    //If there is only one typing user, show the user's name
    if (typingUsers.length == 1) {
      final name = _getDisplayNameFromUserId(typingUsers.first.id, ref);
      return lang.typingUser1(name);
    } else if (typingUsers.length == 2) {
      //If there are two typing users, show the users' names
      final name1 = _getDisplayNameFromUserId(typingUsers.first.id, ref);
      final name2 = _getDisplayNameFromUserId(typingUsers.last.id, ref);
      return lang.typingUser2(name1, name2);
    } else {
      //If there are more than two typing users, show the first user's name and the number of users
      final name = _getDisplayNameFromUserId(typingUsers.first.id, ref);
      return lang.typingUserN(name, typingUsers.length - 1);
    }
  }

  String _getDisplayNameFromUserId(String userId, WidgetRef ref) {
    final avatarInfo = ref.watch(
      memberAvatarInfoProvider((userId: userId, roomId: roomId)),
    );
    return avatarInfo.displayName ?? userId;
  }

  List<User> _getTypingUsers(WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users ?? [];
  }

  bool _getIsDM(WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId));
    return isDM.valueOrNull ?? false;
  }
}
