import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BriefRoomEntry extends ConsumerWidget {
  final String roomId;
  final String? selectedValue;
  final String canCheck;
  final String keyPrefix;
  final Function(String)? onSelect;
  final Widget Function(bool)? trailingBuilder;
  final Widget? subtitle;

  const BriefRoomEntry({
    super.key,
    required this.roomId,
    required this.canCheck,
    this.onSelect,
    required this.keyPrefix,
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
    Widget? trailing = trailingBuilder.map((cb) => cb(canLink));
    if (trailing == null && selectedValue == roomId) {
      trailing = const Icon(Icons.check_circle_outline);
    }
    return ListTile(
      key: Key('$keyPrefix-$roomId'),
      enabled: canLink,
      leading: RoomAvatarBuilder(
        roomId: roomId,
        avatarSize: 24,
      ),
      title: Text(roomName),
      subtitle: subtitle,
      trailing: trailing,
      onTap: canLink ? onSelect.map((cb) => () => cb(roomId)) : null,
    );
  }
}
