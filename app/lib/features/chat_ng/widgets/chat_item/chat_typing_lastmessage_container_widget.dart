import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatTypingLastMessageContainerWidget extends ConsumerWidget {
  final String roomId;
  final bool isSelected;
  const ChatTypingLastMessageContainerWidget({super.key, required this.roomId, required this.isSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = _getTypingUsers(ref);
    return typingUsers.isNotEmpty
        ? TypingIndicator(roomId: roomId, isSelected: isSelected)
        : LastMessageWidget(roomId: roomId);
  }

  List<User> _getTypingUsers(WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users ?? [];
  }
}
