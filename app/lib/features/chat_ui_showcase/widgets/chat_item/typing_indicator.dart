import 'package:acter/common/providers/room_providers.dart';
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
    final secondaryColor = theme.colorScheme.surfaceTint;
    final text = _getTypingText(context, ref, typingUsers);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
    );
  }

  String _getTypingText(BuildContext context, ref, List<User> typingUsers) {
    final lang = L10n.of(context);
    final isDM = mockIsDM ?? _getIsDM(ref);

    if (isDM) return lang.typing;

    if (typingUsers.length == 1) return lang.typingUser1(typingUsers[0]);
    if (typingUsers.length == 2) {
      return lang.typingUser2(typingUsers[0], typingUsers[1]);
    }
    return lang.typingUserN(typingUsers[0], {typingUsers.length - 1});
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
