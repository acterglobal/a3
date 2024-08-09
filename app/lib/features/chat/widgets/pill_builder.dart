import 'package:acter/common/toolkit/buttons/room_chip.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:flutter/material.dart';

Widget pillBuilder({
  required BuildContext context,
  required String roomId,
  required String identifier,
  required String uri,
  required Function()? onTap,
}) {
  return switch (identifier.characters.first) {
    '@' => UserChip(
        roomId: roomId,
        memberId: identifier,
      ),
    '!' => RoomChip(roomId: identifier),
    _ => InkWell(
        onTap: onTap,
        child: Text(identifier),
      ),
  };
}
