import 'package:acter/features/chat_ng/widgets/chat_room/app_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRoomShowcasePage extends ConsumerWidget {
  final String roomId;
  const ChatRoomShowcasePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: ChatRoomAppBarWidget(roomId: roomId, ref: ref),
      body: Center(child: Text('Room ID: $roomId')),
    );
  }
}
