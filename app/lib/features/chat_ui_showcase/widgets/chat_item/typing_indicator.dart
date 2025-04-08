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
  final List<User>? mockTypingUsers;
  final bool? mockIsDM;

  const TypingIndicator({
    super.key,
    required this.roomId,
    this.mockTypingUsers,
    this.mockIsDM,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = mockTypingUsers ?? _getTypingUsers(ref);
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.onSurface;
    final text = _getTypingText(context, ref, typingUsers);

    return Row(
      children: [
        if (text.isNotEmpty) ...[
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
          const SizedBox(width: 4),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AnimatedCircles(theme: theme.typingIndicatorTheme),
        ),
      ],
    );
  }

  String _getTypingText(BuildContext context, ref, List<User> typingUsers) {
    final lang = L10n.of(context);
    final isDM = mockIsDM ?? _getIsDM(ref);

    if (isDM) return '';

    if (typingUsers.isEmpty) return '';

    if (typingUsers.length == 1) {
      final name = _getDisplayNameFromUserId(typingUsers.first.id, ref);
      return lang.typingUser1(name);
    } else if (typingUsers.length == 2) {
      final name1 = _getDisplayNameFromUserId(typingUsers.first.id, ref);
      final name2 = _getDisplayNameFromUserId(typingUsers.last.id, ref);
      return lang.typingUser2(name1, name2);
    } else {
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
