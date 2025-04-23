import 'package:flutter/material.dart';

class ChatRoomShowcasePage extends StatelessWidget {
  final String roomId;
  const ChatRoomShowcasePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat Messages Showcase')),
      body: Text('Room ID: $roomId'),
    );
  }
}
