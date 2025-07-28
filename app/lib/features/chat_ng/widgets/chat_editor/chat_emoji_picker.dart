import 'package:acter/common/widgets/emoji_picker_widget.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatEmojiPicker extends ConsumerWidget {
  final Function(String) onSelect;
  const ChatEmojiPicker({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.sizeOf(context);
    return EmojiPickerWidget(
      size: Size(screenSize.width, screenSize.height * 0.3),
      onEmojiSelected: (category, emoji) {
        onSelect(emoji.emoji);
      },
      // onBackspacePressed: () => handleBackspacePressed(ref),
      onClosePicker: () =>
          ref.read(chatInputProvider.notifier).emojiPickerVisible(false),
    );
  }
}
