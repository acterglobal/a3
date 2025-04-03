import 'package:acter/features/chat_ui_showcase/widgets/chat_list_item_showcase.dart';
import 'package:flutter/material.dart';

class ChatListShowcasePage extends StatelessWidget {
  const ChatListShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat List Showcase')),
      body: ListView.separated(
        separatorBuilder: (context, index) {
          return Divider(
            color: Theme.of(
              context,
            ).unselectedWidgetColor.withValues(alpha: 0.5),
          );
        },
        itemCount: 20,
        itemBuilder: (context, index) => ChatListItemShowcase(index: index),
      ),
    );
  }
}
