import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter/features/chat_ng/widgets/chat_bubble.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';

class TextMessageEvent extends StatelessWidget {
  final String roomId;
  final MsgContent content;
  final bool isUser;
  final bool nextMessageGroup;
  final bool wasEdited;

  const TextMessageEvent({
    super.key,
    required this.content,
    required this.isUser,
    required this.nextMessageGroup,
    required this.roomId,
    this.wasEdited = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = content.formattedBody() ?? content.body();

    final Widget inner = Html(
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
      data: body,
    );
    if (isUser) {
      return ChatBubble.user(
        context: context,
        wasEdited: wasEdited,
        nextMessageGroup: nextMessageGroup,
        child: inner,
      );
    }
    return ChatBubble(
      context: context,
      nextMessageGroup: nextMessageGroup,
      wasEdited: wasEdited,
      child: Html(
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
        data: body,
      ),
    );
  }
}
