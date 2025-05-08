import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final BoxDecoration decoration;
  final MainAxisAlignment bubbleAlignment;
  final int? timestamp;
  final bool isEdited;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.bubbleAlignment,
    required this.decoration,
    this.isEdited = false,
    this.messageWidth,
    this.timestamp,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required BuildContext context,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    final theme = Theme.of(context);

    final cornersRadius = Radius.circular(16);
    final flatRadius = Radius.circular(0);

    final topLeft = isFirstMessageBySender ? cornersRadius : flatRadius;
    final topRight = isFirstMessageBySender ? cornersRadius : flatRadius;
    final bottomLeft = flatRadius;
    final bottomRight = isLastMessageBySender ? cornersRadius : flatRadius;

    return ChatBubble._inner(
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
      bubbleAlignment: MainAxisAlignment.start,
      isEdited: isEdited,
      timestamp: timestamp,
      child: child,
    );
  }

  // for user's own messages
  factory ChatBubble.me({
    Key? key,
    required BuildContext context,
    required Widget child,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    final theme = Theme.of(context);

    final cornersRadius = Radius.circular(16);
    final flatRadius = Radius.circular(0);

    final topLeft = isFirstMessageBySender ? cornersRadius : flatRadius;
    final topRight = isFirstMessageBySender ? cornersRadius : flatRadius;
    final bottomLeft = isLastMessageBySender ? cornersRadius : flatRadius;
    final bottomRight = flatRadius;

    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.only(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
      bubbleAlignment: MainAxisAlignment.end,
      isEdited: isEdited,
      timestamp: timestamp,
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
    final msgWidth = messageWidth?.toDouble();
    final defaultWidth =
        context.isLargeScreen ? size.width * 0.5 : size.width * 0.75;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: bubbleAlignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 5),
          IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(maxWidth: msgWidth ?? defaultWidth),
              decoration: decoration,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    child,
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isEdited)
                          Text(
                            L10n.of(context).edited,
                            style: chatTheme.emptyChatPlaceholderTextStyle
                                .copyWith(fontSize: 12),
                          ),
                        if (isEdited && timestamp != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              '.',
                              style: chatTheme.emptyChatPlaceholderTextStyle
                                  .copyWith(fontSize: 12),
                            ),
                          ),
                        if (timestamp != null)
                          MessageTimestampWidget(
                            timestamp: timestamp.expect('should not be null'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
