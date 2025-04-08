import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_user.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TypingIndicator extends ConsumerWidget {
  final String roomId;
  final List<MockUser>? mockTypingUsers;

  const TypingIndicator({
    super.key,
    required this.roomId,
    this.mockTypingUsers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    if (users == null || users.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.surfaceTint;
    final text = _getTypingText(context, ref);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
    );
  }

  String _getTypingText(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final isDM = _getIsDM(ref);
    final users = _getTypingUsers(ref);

    if (isDM) return lang.typing;

    if (users.length == 1) return lang.typingUser1(users[0]);
    if (users.length == 2) return lang.typingUser2(users[0], users[1]);
    return lang.typingUserN(users[0], {users.length - 1});
  }

  List<User> _getTypingUsers(WidgetRef ref) {
    if (mockTypingUsers != null) return mockTypingUsers!;

    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users ?? [];
  }

  bool _getIsDM(WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId));
    return isDM.valueOrNull ?? false;
  }
}
