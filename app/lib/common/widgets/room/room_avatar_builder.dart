import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomAvatarBuilder extends ConsumerWidget {
  final String roomId;
  final EdgeInsetsGeometry? padding;
  final double avatarSize;

  const RoomAvatarBuilder({
    super.key,
    required this.roomId,
    this.padding,
    this.avatarSize = 14,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final child = ActerAvatar(
      options: AvatarOptions(
        roomAvatarInfo,
        size: avatarSize,
      ),
    );
    return padding.map((p0) => Padding(padding: p0, child: child)) ?? child;
  }
}
