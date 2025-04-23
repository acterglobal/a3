import 'package:flutter/material.dart';

class ChatMessagesShowcasePage extends StatelessWidget {
  final String roomId;
  const ChatMessagesShowcasePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Messages Showcase')),
      body: Text('Room ID: $roomId'),
    );
  }
}
