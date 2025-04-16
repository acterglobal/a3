import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/last_message_text_style.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IconMessageWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;
  final String eventName;
  final IconData icon;

  const IconMessageWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
    required this.eventName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Providers
    final isDM = ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    final senderName = ref.watch(
      lastMessageDisplayNameProvider((
        roomId: roomId,
        userId: eventItem.sender(),
      )),
    );
    final textStyle = lastMessageTextStyle(context, ref, roomId);

    //Render
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!isDM) Text('$senderName : ', style: textStyle),
        Icon(icon, size: 14, color: textStyle?.color),
        const SizedBox(width: 4),
        Text(eventName, style: textStyle),
      ],
    );
  }
}
