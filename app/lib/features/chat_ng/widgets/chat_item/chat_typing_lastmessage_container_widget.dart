import 'package:acter/features/chat_ng/providers/chat_typing_event_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatTypingLastMessageContainerWidget extends ConsumerWidget {
  final String roomId;
  const ChatTypingLastMessageContainerWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(isSomeoneTypingProvider(roomId))
        ? TypingIndicator(roomId: roomId)
        : LastMessageWidget(roomId: roomId);
  }
}
