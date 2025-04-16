import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/last_message_text_style.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeneralMessageEventWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const GeneralMessageEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
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
    final message = ref.watch(lastMessageTextProvider(eventItem));

    //Get text style
    final textStyle = lastMessageTextStyle(context, ref, roomId);

    //Render
    final List<InlineSpan> spans = [];
    if (!isDM) spans.add(TextSpan(text: '$senderName : ', style: textStyle));
    spans.add(TextSpan(text: message ?? '', style: textStyle));

    return RichText(text: TextSpan(children: spans, style: textStyle));
  }
}
