import 'package:acter/common/toolkit/buttons/room_chip.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:flutter/material.dart';

class PillBuilder extends StatelessWidget {
  final BuildContext context;
  final String roomId;
  final String identifier;
  final String uri;
  const PillBuilder({
    super.key,
    required this.context,
    required this.roomId,
    required this.identifier,
    required this.uri,
  });

  @override
  Widget build(BuildContext context) {
    return switch (identifier.characters.first) {
      '@' => UserChip(
          roomId: roomId,
          memberId: identifier,
        ),
      '!' => RoomChip(roomId: identifier),
      _ => InkWell(
          onTap: () => ChatUtils.onLinkTap(Uri.parse(uri), context),
          child: Text(identifier),
        ),
    };
  }
}
