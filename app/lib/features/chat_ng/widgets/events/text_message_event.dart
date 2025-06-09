import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter/features/chat_ng/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextMessageEvent extends ConsumerStatefulWidget {
  final String roomId;
  final MsgContent content;
  final bool isNotice;
  final bool isReply;
  final Widget? repliedTo;

  const TextMessageEvent({
    super.key,
    required this.content,
    required this.roomId,
    this.isNotice = false,
    this.isReply = false,
    this.repliedTo,
  });

  @override
  ConsumerState<TextMessageEvent> createState() => _TextMessageEventState();
}

class _TextMessageEventState extends ConsumerState<TextMessageEvent> {
  late String body;
  String? bodyFormatted;

  @override
  void initState() {
    super.initState();
    bodyFormatted = widget.content.formattedBody();
    body = widget.content.body();
  }

  @override
  void didUpdateWidget(TextMessageEvent oldWidget) {
    super.didUpdateWidget(oldWidget);
    bodyFormatted = widget.content.formattedBody();
    body = widget.content.body();
  }

  @override
  Widget build(BuildContext context) {
    final inner =
        (isOnlyEmojis(body))
            ? _buildEmojiMessage(context)
            : _buildTextMessage(context);

    final repliedTo = widget.repliedTo;
    if (widget.isReply || repliedTo == null) {
      // we return the widget without any additional reply data
      return inner;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [repliedTo, const SizedBox(height: 10), inner],
    );
  }

  // emoji only special message
  Widget _buildEmojiMessage(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Text(
      body, // what about formatted body?
      style: EmojiConfig.emojiTextStyle?.copyWith(fontSize: 28),
      maxLines: widget.isReply ? 2 : null,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _buildTextMessage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final color =
        widget.isNotice
            ? colorScheme.onSurface.withValues(alpha: 0.5)
            : colorScheme.onSurface.withValues(alpha: 0.9);

    final textStyle = textTheme.bodySmall?.copyWith(
      color: color,
      overflow: widget.isNotice ? TextOverflow.ellipsis : null,
    );

    final html = bodyFormatted;
    if (html != null) {
      return RenderHtml(
        text: html,
        roomId: widget.roomId,
        shrinkToFit: true,
        maxLines: widget.isReply ? 2 : null,
        defaultTextStyle: textStyle,
      );
    }

    // fallback to text with auto-link support if we don't have HTML
    return RenderHtml.text(
      text: body,
      roomId: widget.roomId,
      shrinkToFit: true,
      maxLines: widget.isReply ? 2 : null,
      defaultTextStyle: textStyle,
    );
  }
}
