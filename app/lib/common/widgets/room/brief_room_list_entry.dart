import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BriefRoomEntry extends ConsumerWidget {
  final String roomId;
  final String? selectedValue;
  final String canCheck;
  final String keyPrefix;
  final Function(String) onSelect;
  final DisplayMode avatarDisplayMode;
  const BriefRoomEntry({
    super.key,
    required this.roomId,
    required this.canCheck,
    required this.onSelect,
    required this.avatarDisplayMode,
    this.keyPrefix = 'brief-room',
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomData =
        ref.watch(briefRoomItemWithMembershipProvider(roomId)).valueOrNull;
    final canLink =
        roomData != null && roomData.membership!.canString(canCheck);
    return ListTile(
      key: Key('$keyPrefix-$roomId'),
      enabled: canLink,
      leading: ActerAvatar(
        mode: avatarDisplayMode,
        avatarInfo: roomData == null
            ? AvatarInfo(uniqueId: roomId)
            : AvatarInfo(
                uniqueId: roomId,
                displayName: roomData.roomProfileData.displayName,
                avatar: roomData.roomProfileData.getAvatarImage(),
              ),
        size: 24,
      ),
      title: roomData != null
          ? Text(roomData.roomProfileData.displayName ?? roomId)
          : Text(roomId),
      trailing: selectedValue == roomId
          ? const Icon(Icons.check_circle_outline)
          : null,
      onTap: canLink ? () => onSelect(roomId) : null,
    );
  }
}
