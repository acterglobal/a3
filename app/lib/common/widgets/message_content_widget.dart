import 'package:acter/common/widgets/render_html.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class MessageContentWidget extends StatelessWidget {
  final MsgContent msgContent;
  final String roomId;

  const MessageContentWidget({
    super.key,
    required this.msgContent,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = msgContent.formattedBody();
    final messageTextStyle = Theme.of(context).textTheme.bodyMedium;

    return formatted != null
        ? RenderHtml(
            text: formatted,
            defaultTextStyle: messageTextStyle,
            roomId: roomId,
          )
        : Text(msgContent.body(), style: messageTextStyle);
  }
}
