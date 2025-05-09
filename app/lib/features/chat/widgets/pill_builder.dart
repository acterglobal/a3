import 'package:acter/features/room/widgets/room_chip.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActerPillBuilder extends ConsumerWidget {
  final String identifier;
  final String? roomId;
  final String uri;

  const ActerPillBuilder({
    super.key,
    required this.identifier,
    required this.uri,
    this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (identifier.characters.first) {
      '@' => UserChip(roomId: roomId, memberId: identifier),
      '!' => RoomChip(roomId: identifier, uri: uri),
      _ => InkWell(
        child: Text(identifier),
        onTap: () => onMessageLinkTap(Uri.parse(uri), ref, context),
      ),
    };
  }
}
