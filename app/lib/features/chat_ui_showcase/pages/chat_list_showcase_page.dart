import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/chat/widgets/animated_chats_list_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_list.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class ChatListShowcasePage extends StatelessWidget {
  const ChatListShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.chat),
        actions: [PlusIconWidget(onPressed: () {})],
      ),
      body: AnimatedChatsListWidget(
        entries: mockChatList.map((e) => e.roomId).toList(),
      ),
    );
  }
}
