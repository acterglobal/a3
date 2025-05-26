import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

enum TextMessageType { regular, reply, emoji, notice }

class TextMessageEvent extends ConsumerWidget {
  final String roomId;
  final MsgContent content;
  final TextMessageType _type;
  final bool _isMe; // Only needed for emoji messages to determine style
  final Widget? repliedTo;

  const TextMessageEvent.inner({
    super.key,
    required this.content,
    required this.roomId,
    required TextMessageType type,
    bool isMe = false,
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
    Widget? repliedTo,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.notice,
      repliedTo: repliedTo,
    );
  }
  // Default factory constructor
  factory TextMessageEvent({
    Key? key,
    required MsgContent content,
    required String roomId,
    Widget? repliedTo,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.regular,
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
        child: Html(
          data: body,
          defaultTextStyle: emojiTextStyle.copyWith(fontFamily: emojiFont),
        ),
      );
    }
    final replied = repliedTo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (replied != null) ...[replied, const SizedBox(height: 10)],

        Html(
          linkStyle: TextStyle(
            color: colorScheme.onPrimary,
            decoration: TextDecoration.underline,
          ),
          shrinkToFit: true,
          pillBuilder:
              ({
                required String identifier,
                required String url,
                OnPillTap? onTap,
              }) => ActerPillBuilder(
                identifier: identifier,
                uri: url,
                roomId: roomId,
              ),
          renderNewlines: true,
          maxLines: _type == TextMessageType.reply ? 2 : null,
          onLinkTap: (Uri uri) {
            openUri(ref: ref, uri: uri, lang: L10n.of(context));
          },
          defaultTextStyle: textTheme.bodySmall?.copyWith(
            color:
                _type == TextMessageType.notice
                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                    : colorScheme.onSurface.withValues(alpha: 0.9),
            overflow:
                _type == TextMessageType.reply ? TextOverflow.ellipsis : null,
          ),
          data: body,
        ),
      ],
    );
  }
}
