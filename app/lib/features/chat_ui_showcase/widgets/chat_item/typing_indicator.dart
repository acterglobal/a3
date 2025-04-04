import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final List<String> users;
  const TypingIndicator({super.key, required this.users});

  @override
  Widget build(BuildContext context) {
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

    if (users.isEmpty) {
      return lang.typing;
    } else if (users.length == 1) {
      return lang.typingUser1(users[0]);
    } else if (users.length == 2) {
      return lang.typingUser2(users[0], users[1]);
    } else {
      return lang.typingUserN(users[0], {users.length - 1});
    }
  }
}
