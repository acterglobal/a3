import 'package:flutter/material.dart';

class ChatMessagesShowcasePage extends StatelessWidget {
  const ChatMessagesShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Showcase')),
      body: Center(child: const Text('Chat MessagesShowcase')),
    );
  }
}
