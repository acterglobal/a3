import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/features/chat_ng/widgets/reply_preview.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ChatBubble extends StatelessWidget {
  final Widget child;
  final int? messageWidth;
  final Map<String, dynamic> metadata;
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
    required Map<String, dynamic> metadata,
    int? messageWidth,
  }) {
    final theme = Theme.of(context);
    bool nextMessageGroup = metadata['nextMessageGroup'];
    return ChatBubble._inner(
      metadata: metadata,
      messageWidth: messageWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(nextMessageGroup ? 16 : 4),
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
    int? messageWidth,
    required Map<String, dynamic> metadata,
  }) {
    final theme = Theme.of(context);
    bool nextMessageGroup = metadata['nextMessageGroup'];

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
          bottomRight: Radius.circular(nextMessageGroup ? 16 : 4),
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
    // whether message is edited
    bool wasEdited = metadata['wasEdited'];
    // whether message is reply and has original event
    String? repliedTo = metadata['repliedTo'];

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
          Align(
            alignment: Alignment(0.9, 0.0),
            child: Visibility(
              visible: wasEdited,
              child: Text(
                L10n.of(context).edited,
                style: chatTheme.emptyChatPlaceholderTextStyle
                    .copyWith(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
