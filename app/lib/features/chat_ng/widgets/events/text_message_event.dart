import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';

enum TextMessageType {
  regular,
  reply,
  emoji,
  notice,
}

class TextMessageEvent extends StatelessWidget {
  final String roomId;
  final MsgContent content;
  final TextMessageType _type;
  final bool _isUser; // Only needed for emoji messages to determine style

  const TextMessageEvent.inner({
    super.key,
    required this.content,
    required this.roomId,
    required TextMessageType type,
    bool isMe = false,
  })  : _type = type,
        _isUser = isMe;

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
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.notice,
    );
  }

  // Default factory constructor
  factory TextMessageEvent({
    Key? key,
    required MsgContent content,
    required String roomId,
  }) {
    return TextMessageEvent.inner(
      key: key,
      content: content,
      roomId: roomId,
      type: TextMessageType.regular,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chatTheme = Theme.of(context).chatTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final body = content.formattedBody() ?? content.body();

    // Handle emoji messages
    if (_type == TextMessageType.emoji) {
      final emojiTextStyle = _isUser
          ? chatTheme.sentEmojiMessageTextStyle
          : chatTheme.receivedEmojiMessageTextStyle;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          content.body(),
          style: emojiTextStyle.copyWith(
            fontFamily: emojiFont,
          ),
          maxLines: _type == TextMessageType.reply ? 3 : null,
        ),
      );
    }

    return Html(
      shrinkToFit: true,
      pillBuilder: ({
        required String identifier,
        required String url,
        OnPillTap? onTap,
      }) =>
          ActerPillBuilder(
        identifier: identifier,
        uri: url,
        roomId: roomId,
      ),
      renderNewlines: true,
      maxLines: _type == TextMessageType.reply ? 2 : null,
      defaultTextStyle: textTheme.bodySmall?.copyWith(
        color: _type == TextMessageType.notice
            ? colorScheme.onSurface.withOpacity(0.5)
            : null,
        overflow: _type == TextMessageType.reply ? TextOverflow.ellipsis : null,
      ),
      data: body,
    );
  }
}
