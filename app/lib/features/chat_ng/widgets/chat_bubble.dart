import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/l10n/generated/l10n.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final BoxDecoration decoration;
  final MainAxisAlignment bubbleAlignment;
  final bool isEdited;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.bubbleAlignment,
    required this.decoration,
    this.isEdited = false,
    this.messageWidth,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required BuildContext context,
    bool isLastMessageBySender = false,
    bool isEdited = false,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    return ChatBubble._inner(
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isLastMessageBySender ? 4 : 16),
          bottomRight: Radius.circular(16),
        ),
      ),
      bubbleAlignment: MainAxisAlignment.start,
      isEdited: isEdited,
      child: child,
    );
  }

  // for user's own messages
  factory ChatBubble.me({
    Key? key,
    required BuildContext context,
    required Widget child,
    bool isLastMessageBySender = false,
    bool isEdited = false,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(isLastMessageBySender ? 16 : 4),
        ),
      ),
      bubbleAlignment: MainAxisAlignment.end,
      isEdited: isEdited,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;
    final size = MediaQuery.sizeOf(context);
    final msgWidth = messageWidth.map((w) => w.toDouble());
    final defaultWidth =
        context.isLargeScreen ? size.width * 0.5 : size.width * 0.75;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: bubbleAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 5),
          Container(
            constraints: BoxConstraints(maxWidth: msgWidth ?? defaultWidth),
            width: msgWidth,
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  child,
                  if (isEdited) ...[
                    const SizedBox(width: 5),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        L10n.of(context).edited,
                        style: chatTheme.emptyChatPlaceholderTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
