import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/icon_meessage_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/general_message_event_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RoomMessageEventWidget extends StatelessWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const RoomMessageEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return switch (eventItem.msgType()) {
      'm.text' => GeneralMessageEventWidget(
        roomId: roomId,
        eventItem: eventItem,
      ),
      'm.image' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.image,
        icon: PhosphorIcons.image(),
      ),
      'm.video' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.video,
        icon: PhosphorIcons.video(),
      ),
      'm.audio' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.audio,
        icon: PhosphorIcons.musicNote(),
      ),
      'm.file' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.file,
        icon: PhosphorIcons.file(),
      ),
      'm.location' => IconMessageWidget(
        roomId: roomId,
        eventItem: eventItem,
        eventName: lang.location,
        icon: PhosphorIcons.mapPin(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
