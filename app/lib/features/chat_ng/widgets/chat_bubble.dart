import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:flutter_svg/svg.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final MainAxisAlignment bubbleAlignment;
  final int? timestamp;
  final bool isEdited;
  final String? displayName;
  final bool isMe;
  final bool isFirstMessageBySender;
  final bool isLastMessageBySender;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.bubbleAlignment,
    required this.isFirstMessageBySender,
    required this.isLastMessageBySender,
    this.isEdited = false,
    this.messageWidth,
    this.timestamp,
    this.displayName,
    this.isMe = false,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    String? displayName,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    return ChatBubble._inner(
      messageWidth: messageWidth,
      displayName: displayName,
      bubbleAlignment: MainAxisAlignment.start,
      isEdited: isEdited,
      timestamp: timestamp,
      isMe: false,
      isFirstMessageBySender: isFirstMessageBySender,
      isLastMessageBySender: isLastMessageBySender,
      child: Stack(alignment: Alignment.bottomLeft, children: [child]),
    );
  }

  // for user's own messages
  factory ChatBubble.me({
    Key? key,
    required Widget child,
    required bool isFirstMessageBySender,
    required bool isLastMessageBySender,
    String? displayName,
    bool isEdited = false,
    int? messageWidth,
    int? timestamp,
  }) {
    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      displayName: displayName,
      bubbleAlignment: MainAxisAlignment.end,
      isEdited: isEdited,
      timestamp: timestamp,
      isMe: true,
      isFirstMessageBySender: isFirstMessageBySender,
      isLastMessageBySender: isLastMessageBySender,
      child: child,
    );
  }

  BoxDecoration _getDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final cornersRadius = Radius.circular(16);
    final flatRadius = Radius.circular(8);

    if (isMe) {
      final topRight = isFirstMessageBySender ? cornersRadius : flatRadius;
      final bottomRight = isLastMessageBySender ? cornersRadius : flatRadius;

      return BoxDecoration(
        gradient: theme.chatTheme.senderChatBubbleGradient,
        borderRadius: BorderRadius.only(
          topLeft: cornersRadius,
          topRight: topRight,
          bottomLeft: cornersRadius,
          bottomRight: bottomRight,
        ),
      );
    } else {
      final topLeft = isFirstMessageBySender ? cornersRadius : flatRadius;
      final bottomLeft = isLastMessageBySender ? cornersRadius : flatRadius;

      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            theme.colorScheme.surface.withBlue(40),
            theme.colorScheme.surface.withBlue(20),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: topLeft,
          topRight: cornersRadius,
          bottomLeft: bottomLeft,
          bottomRight: cornersRadius,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msgWidth = messageWidth?.toDouble();
    final defaultWidth = defaultMessageMaxWidth(context);
    final String? name = displayName;

    final Widget wrappedChild =
        isMe
            ? DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
              child: child,
            )
            : child;

    return IntrinsicWidth(
      child: Stack(
        alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
        children: [
          if (isLastMessageBySender)
            isMe
                ? Positioned(
                  bottom: 0,
                  right: 4,
                  child: SvgPicture.asset(
                    'assets/icon/ic_right_chat_bubble_corner.svg',
                  ),
                )
                : Positioned(
                  bottom: 0,
                  left: 4,
                  child: SvgPicture.asset(
                    'assets/icon/ic_left_chat_bubble_corner.svg',
                  ),
                ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(10),
            constraints: BoxConstraints(maxWidth: msgWidth ?? defaultWidth),
            decoration: _getDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name != null) ...[
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          chatBubbleDisplayNameColors[name.hashCode.abs() %
                              chatBubbleDisplayNameColors.length],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  clipBehavior: Clip.none,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    wrappedChild,
                    _buildTimestampAndEditedLabel(context),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
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
