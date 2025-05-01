import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

enum TextMessageType { regular, reply, emoji, notice }

class TextMessageEvent extends ConsumerWidget {
  final String roomId;
  final MsgContent content;
  final TextMessageType _type;
  final bool _isMe; // Only needed for emoji messages to determine style
  final String? displayName;
  final Widget? repliedTo;

  const TextMessageEvent.inner({
    super.key,
    required this.content,
    required this.roomId,
    required TextMessageType type,
    bool isMe = false,
    this.displayName,
    this.repliedTo,
  }) : _type = type,
       _isMe = isMe;

  factory TextMessageEvent.emoji({
    Key? key,
    required MsgContent content,
    required String roomId,
    required bool isMe,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.emoji,
      isMe: isMe,
    );
  }

  // Factory constructor for reply messages
  factory TextMessageEvent.reply({
    Key? key,
    required MsgContent content,
    required String roomId,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.reply,
    );
  }

  // Factory constructor for notice messages
  factory TextMessageEvent.notice({
    Key? key,
    required MsgContent content,
    required String roomId,
    String? displayName,
    Widget? repliedTo,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.notice,
      displayName: displayName,
      repliedTo: repliedTo,
    );
  }

  // Default factory constructor
  factory TextMessageEvent({
    Key? key,
    required MsgContent content,
    required String roomId,
    String? displayName,
    Widget? repliedTo,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.regular,
      displayName: displayName,
      repliedTo: repliedTo,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final chatTheme = Theme.of(context).chatTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final body = content.formattedBody() ?? md.markdownToHtml(content.body());

    // Handle emoji messages
    if (_type == TextMessageType.emoji) {
      final emojiTextStyle =
          _isMe
              ? chatTheme.sentEmojiMessageTextStyle
              : chatTheme.receivedEmojiMessageTextStyle;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: RenderHtml(
          text: body,
          defaultTextStyle: emojiTextStyle.copyWith(fontFamily: emojiFont),
          roomId: roomId,
        ),
      );
    }
    final dp = displayName;
    final replied = repliedTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dp != null) ...[
          Text(
            dp,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (replied != null) ...[replied, const SizedBox(height: 10)],
        RenderHtml(
          text: body,
          roomId: roomId,
          shrinkToFit: true,
          renderNewlines: true,
          maxLines: _type == TextMessageType.reply ? 2 : null,
          defaultTextStyle: textTheme.bodySmall?.copyWith(
            color:
                _type == TextMessageType.notice
                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
            overflow:
                _type == TextMessageType.reply ? TextOverflow.ellipsis : null,
          ),
        ),
      ],
    );
  }
}
