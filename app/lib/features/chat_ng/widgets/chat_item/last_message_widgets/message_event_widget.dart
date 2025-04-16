import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/icon_meessage_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/text_message_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MessageEventWidget extends StatelessWidget {
  final String roomId;
  final TimelineEventItem eventItem;
  const MessageEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context) {
    return switch (eventItem.msgType()) {
      'm.text' => TextMessageWidget(roomId: roomId, eventItem: eventItem),
      'm.image' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        icon: PhosphorIcons.image(),
      ),
      'm.video' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        icon: PhosphorIcons.video(),
      ),
      'm.audio' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        icon: PhosphorIcons.musicNote(),
      ),
      'm.file' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        icon: PhosphorIcons.file(),
      ),
      'm.location' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        icon: PhosphorIcons.mapPin(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
