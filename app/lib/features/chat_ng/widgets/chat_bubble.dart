import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// Chat Bubble UI
class ChatBubble extends StatelessWidget {
  final int? messageWidth;
  // inner content
  final Widget child;
  final bool isUser;
  final bool showAvatar;
  final bool wasEdited;

  const ChatBubble({
    super.key,
    required this.child,
    this.messageWidth,
    this.isUser = false,
    this.showAvatar = true,
    this.wasEdited = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatTheme = Theme.of(context).chatTheme;
    final size = MediaQuery.sizeOf(context);
    final msgWidth = messageWidth.map((w) => w.toDouble());
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: msgWidth ?? size.width),
            width: msgWidth,
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser || !showAvatar ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: child,
            ),
          ),
          Visibility(
            visible: wasEdited,
            child: Text(
              L10n.of(context).edited,
              style: chatTheme.emptyChatPlaceholderTextStyle
                  .copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
