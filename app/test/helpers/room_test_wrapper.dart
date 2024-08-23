// Wrapper widget to force rebuilds
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:flutter/material.dart';

// This helper widget ensures we are rebuilding the custom input with new room Id
class RoomTestWrapper extends StatefulWidget {
  final String roomId;
  const RoomTestWrapper({super.key, required this.roomId});

  @override
  RoomTestWrapperState createState() => RoomTestWrapperState();
}

class RoomTestWrapperState extends State<RoomTestWrapper> {
  late String currentRoomId;

  @override
  void initState() {
    super.initState();
    currentRoomId = widget.roomId;
  }

  void switchRoom(String newRoomId) {
    setState(() {
      currentRoomId = newRoomId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomChatInput(roomId: currentRoomId);
  }
}
