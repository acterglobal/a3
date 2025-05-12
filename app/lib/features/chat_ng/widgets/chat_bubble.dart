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
  final String? displayName;
  final bool isMe;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.bubbleAlignment,
    required this.decoration,
    this.isEdited = false,
    this.messageWidth,
    this.timestamp,
    this.displayName,
    this.isMe = false,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required BuildContext context,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    String? displayName,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    final theme = Theme.of(context);

    final cornersRadius = Radius.circular(16);
    final flatRadius = Radius.circular(0);

    final topLeft = isFirstMessageBySender ? cornersRadius : flatRadius;

    return ChatBubble._inner(
      messageWidth: messageWidth,
      displayName: displayName,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: topLeft,
          topRight: cornersRadius,
          bottomLeft: flatRadius,
          bottomRight: cornersRadius,
        ),
      ),
      bubbleAlignment: MainAxisAlignment.start,
      isEdited: isEdited,
      timestamp: timestamp,
      isMe: false,
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
    String? displayName,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    final theme = Theme.of(context);

    final cornersRadius = Radius.circular(16);
    final flatRadius = Radius.circular(0);

    final topRight = isFirstMessageBySender ? cornersRadius : flatRadius;

    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      displayName: displayName,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: cornersRadius,
          topRight: topRight,
          bottomLeft: cornersRadius,
          bottomRight: flatRadius,
        ),
      ),
      bubbleAlignment: MainAxisAlignment.end,
      isEdited: isEdited,
      timestamp: timestamp,
      isMe: true,
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
    final size = MediaQuery.sizeOf(context);
    final msgWidth = messageWidth?.toDouble();
    final defaultWidth =
        context.isLargeScreen ? size.width * 0.5 : size.width * 0.75;
    final String? name = displayName;

    return IntrinsicWidth(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: msgWidth ?? defaultWidth),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (name != null) ...[
              Text(
                name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Colors.primaries[displayName!.hashCode.abs() %
                          Colors.primaries.length],
                ),
              ),
              const SizedBox(height: 8),
            ],
            child,
            _buildTimestampAndEditedLabel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampAndEditedLabel(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;
    final textStyle = chatTheme.emptyChatPlaceholderTextStyle.copyWith(
      fontSize: 12,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isEdited) ...[
          Text(L10n.of(context).edited, style: textStyle),
          const SizedBox(width: 6),
          Text('-', style: textStyle),
          const SizedBox(width: 6),
        ],
        if (timestamp != null)
          MessageTimestampWidget(
            timestamp: timestamp.expect('should not be null'),
            textColor:
                isMe
                    ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.surfaceTint,
          ),
      ],
    );
  }
}
