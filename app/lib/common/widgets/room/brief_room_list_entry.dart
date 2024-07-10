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
  final Function(String)? onSelect;
  final DisplayMode avatarDisplayMode;
  final Widget Function(bool)? trailingBuilder;
  final Widget? subtitle;
  const BriefRoomEntry({
    super.key,
    required this.roomId,
    required this.canCheck,
    this.onSelect,
    required this.avatarDisplayMode,
    this.keyPrefix = 'brief-room',
    this.selectedValue,
    this.trailingBuilder,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomMembership = ref.watch(roomMembershipProvider(roomId));
    final canLink = roomMembership.maybeWhen(
      data: (membership) => membership?.canString(canCheck) == true,
      orElse: () => false,
    );
    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;
    Widget? trailing;
    if (trailingBuilder != null) {
      trailing = trailingBuilder!(canLink);
    } else if (selectedValue == roomId) {
      trailing = const Icon(Icons.check_circle_outline);
    }
    return ListTile(
      key: Key('$keyPrefix-$roomId'),
      enabled: canLink,
      leading: RoomAvatarBuilder(roomId: roomId, avatarSize: 24),
      title: Text(roomName),
      subtitle: subtitle,
      trailing: trailing,
      onTap: canLink && onSelect != null ? () => onSelect!(roomId) : null,
    );
  }
}
