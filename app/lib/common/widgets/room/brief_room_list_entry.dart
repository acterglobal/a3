import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
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
    final roomData = ref.watch(briefRoomItemWithMembershipProvider(roomId));
    final canLink = roomData.maybeWhen(
      data: (roomData) => roomData.membership!.canString(canCheck),
      orElse: () => false,
    );
    return ListTile(
      key: Key('$keyPrefix-$roomId'),
      enabled: canLink,
      leading: RoomAvatarBuilder(roomId: roomId, avatarSize: 24),
      title: roomData.maybeWhen(
        data: (roomData) =>
            Text(roomData.roomProfileData.displayName ?? roomId),
        orElse: () => Text(roomId),
      ),
      trailing: selectedValue == roomId
          ? const Icon(Icons.check_circle_outline)
          : null,
      onTap: canLink ? () => onSelect(roomId) : null,
    );
  }
}
