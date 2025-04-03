import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListShowcasePage extends StatelessWidget {
  const ChatListShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat List Showcase')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () => context.pushNamed(Routes.chatMessagesShowcase.name),
            title: Text('Chat $index'),
            subtitle: Text('Chat $index'),
            trailing: Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}
