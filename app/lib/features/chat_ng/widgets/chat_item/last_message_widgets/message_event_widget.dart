import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/icon_meessage_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/text_message_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MessageEventWidget extends StatelessWidget {
  final TimelineItem? timelineItem;
  final bool isDM;
  final String? message;
  final String? senderName;
  final TextStyle? textStyle;
  const MessageEventWidget({
    super.key,
    required this.timelineItem,
    this.isDM = false,
    this.message,
    this.senderName,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return switch (timelineItem?.eventItem()?.msgType()) {
      'm.text' => TextMessageWidget(
        isDM: isDM,
        message: message,
        senderName: senderName,
        textStyle: textStyle,
      ),
      'm.image' => IconMessageWidget(
        isDM: isDM,
        icon: PhosphorIcons.image(),
        message: lang.image,
        senderName: senderName,
        textStyle: textStyle,
      ),
      'm.video' => IconMessageWidget(
        isDM: isDM,
        icon: PhosphorIcons.video(),
        message: lang.video,
        senderName: senderName,
        textStyle: textStyle,
      ),
      'm.audio' => IconMessageWidget(
        isDM: isDM,
        icon: PhosphorIcons.musicNote(),
        message: lang.audio,
        senderName: senderName,
        textStyle: textStyle,
      ),
      'm.file' => IconMessageWidget(
        isDM: isDM,
        icon: PhosphorIcons.file(),
        message: lang.file,
        senderName: senderName,
        textStyle: textStyle,
      ),
      'm.location' => IconMessageWidget(
        isDM: isDM,
        icon: PhosphorIcons.mapPin(),
        message: lang.location,
        senderName: senderName,
        textStyle: textStyle,
      ),
      _ => TextMessageWidget(
        isDM: isDM,
        message: message,
        senderName: senderName,
        textStyle: textStyle,
      ),
    };
  }
}
