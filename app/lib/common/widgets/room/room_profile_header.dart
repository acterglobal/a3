import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomProfileHeader extends ConsumerWidget {
  final String roomId;
  const RoomProfileHeader({required this.roomId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    return Column(
      children: [
        ActerAvatar(options: AvatarOptions(roomAvatarInfo, size: 50)),
        const SizedBox(height: 10),
        Text(roomAvatarInfo.displayName ?? ''),
      ],
    );
  }
}
