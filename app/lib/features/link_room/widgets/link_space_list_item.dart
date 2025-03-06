import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/link_room/providers/link_room_providers.dart';
import 'package:acter/features/link_room/widgets/link_room_trailing.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkRoomListItem extends ConsumerWidget {
  final String parentId;
  final String roomId;
  const LinkRoomListItem({
    super.key,
    required this.parentId,
    required this.roomId,
  });

  Widget renderSubtitle(BuildContext context, WidgetRef ref, bool isLinked) {
    if (isLinked) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_outlined,
            size: Theme.of(context).textTheme.bodySmall?.fontSize,
          ),
          SizedBox(width: 3),
          Text(L10n.of(context).isLinked),
        ],
      );
    }

    final canUpgradeChild =
        ref
            .watch(roomMembershipProvider(roomId))
            .valueOrNull
            ?.canString('CanLinkSpaces') ==
        true;

    if (canUpgradeChild) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [Text(L10n.of(context).canLink)],
      );
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(
          Icons.warning_amber_outlined,
          size: Theme.of(context).textTheme.bodySmall?.fontSize,
        ),
        SizedBox(width: 3),
        Text(L10n.of(context).canLinkButNotUpgrade),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (parentId: parentId, childId: roomId);
    final isLinked = ref.watch(isLinkedProvider(query));

    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;

    return ListTile(
      key: Key('space-list-link-$roomId'),
      leading: RoomAvatarBuilder(roomId: roomId, avatarSize: 24),
      title: Text(roomName),
      subtitle: renderSubtitle(context, ref, isLinked),
      trailing: LinkRoomTrailing(
        parentId: parentId,
        roomId: roomId,
        isLinked: isLinked,
        canLink: true,
      ),
    );
  }
}
