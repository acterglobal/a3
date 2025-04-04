import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final List<String> users;
  final bool isDM;
  const TypingIndicator({super.key, required this.users, required this.isDM});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final secondaryColor = theme.colorScheme.secondary;
    final text = _getTypingText(context);

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
    );
  }

  String _getTypingText(BuildContext context) {
    final lang = L10n.of(context);

    if (isDM) return lang.typing;

    if (users.length == 1) return lang.typingUser1(users[0]);
    if (users.length == 2) return lang.typingUser2(users[0], users[1]);
    return lang.typingUserN(users[0], {users.length - 1});
  }
}
