import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_input/chat_editor.dart';
import 'package:acter/features/chat_ng/widgets/chat_input/chat_editor_loading.dart';
import 'package:acter/features/chat_ng/widgets/chat_input/chat_editor_no_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatInput extends ConsumerWidget {
  static const loadingKey = Key('chat-ng-loading');
  static const noAccessKey = Key('chat-ng-no-access');

  final String roomId;
  final void Function(bool)? onTyping;

  const ChatInput({super.key, required this.roomId, this.onTyping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSend = ref.watch(canSendMessageProvider(roomId)).valueOrNull;

    return switch (canSend) {
      true => ChatEditor(
          // we have permission, show editor field
          roomId: roomId,
          onTyping: onTyping,
        ),
      false => const ChatEditorNoAccess(), // no permissions to send messages
      null => const ChatEditorLoading(), // we're still loading
    };
  }
}
