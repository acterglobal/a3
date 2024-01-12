import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomAvatarBuilder extends ConsumerWidget {
  final String roomId;
  final DisplayMode displayMode;
  final EdgeInsetsGeometry? padding;
  final double avatarSize;

  const RoomAvatarBuilder({
    super.key,
    required this.roomId,
    this.padding,
    this.displayMode = DisplayMode.Space,
    this.avatarSize = 14,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomProfile = ref.watch(roomProfileDataProvider(roomId));
    final child = roomProfile.when(
      data: (profile) => ActerAvatar(
        mode: displayMode,
        avatarInfo: AvatarInfo(
          uniqueId: roomId,
          displayName: profile.displayName ?? roomId,
          avatar: profile.getAvatarImage(),
        ),
        size: avatarSize,
      ),
      error: (e, st) {
        debugPrint('ERROR loading room avatar due to $e');
        return ActerAvatar(
          mode: displayMode,
          avatarInfo: AvatarInfo(uniqueId: roomId, displayName: roomId),
          size: avatarSize,
        );
      },
      loading: () => ActerAvatar(
        mode: displayMode,
        avatarInfo: AvatarInfo(uniqueId: roomId, displayName: roomId),
        size: avatarSize,
      ),
    );
    if (padding != null) {
      return Padding(padding: padding!, child: child);
    } else {
      return child;
    }
  }
}
