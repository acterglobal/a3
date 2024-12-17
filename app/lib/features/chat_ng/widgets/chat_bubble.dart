import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/models/message_metadata.dart';
import 'package:acter/features/chat_ng/widgets/reply_preview.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final MessageMetadata metadata;
  final BoxDecoration decoration;
  final CrossAxisAlignment bubbleAlignment;

  // default private constructor
  const ChatBubble._inner({
    super.key,
    required this.child,
    required this.metadata,
    required this.bubbleAlignment,
    required this.decoration,
    this.messageWidth,
  });

  // factory bubble constructor
  factory ChatBubble({
    required Widget child,
    required BuildContext context,
    required MessageMetadata metadata,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    bool isNextMessageInGroup = metadata.isNextMessageInGroup;

    return ChatBubble._inner(
      messageWidth: messageWidth,
      metadata: metadata,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(isNextMessageInGroup ? 16 : 4),
          bottomRight: Radius.circular(16),
        ),
      ),
      bubbleAlignment: CrossAxisAlignment.start,
      child: child,
    );
  }

  // for user's own messages
  factory ChatBubble.user({
    Key? key,
    required BuildContext context,
    required Widget child,
    required MessageMetadata metadata,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    bool isNextMessageInGroup = metadata.isNextMessageInGroup;

    return ChatBubble._inner(
      key: key,
      messageWidth: messageWidth,
      metadata: metadata,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(isNextMessageInGroup ? 16 : 4),
        ),
      ),
      bubbleAlignment: CrossAxisAlignment.end,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onPrimary),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;
    final size = MediaQuery.sizeOf(context);
    final msgWidth = messageWidth.map((w) => w.toDouble());
    // whether it's a replied event and contains original message
    final repliedTo = metadata.repliedTo;
    // whether it's edited message
    final wasEdited = metadata.wasEdited;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: bubbleAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: msgWidth ?? size.width,
            ),
            width: msgWidth,
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repliedTo != null) ...[
                    ReplyPreview(metadata: metadata),
                    const SizedBox(height: 10),
                  ],
                  child,
                ],
              ),
            ),
          ),
          if (wasEdited)
            Align(
              alignment: Alignment(0.9, 0.0),
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
