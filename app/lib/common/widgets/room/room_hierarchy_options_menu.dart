import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/actions/set_child_room_suggested.dart';
import 'package:acter/features/space/actions/unlink_child_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RoomHierarchyOptionsMenu extends ConsumerWidget {
  final String childId;
  final String parentId;
  final bool isSuggested;
  const RoomHierarchyOptionsMenu({
    super.key,
    required this.childId,
    required this.parentId,
    required this.isSuggested,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref
            .watch(roomMembershipProvider(parentId))
            .valueOrNull
            ?.canString('CanLinkSpaces') ==
        true;
    if (!canEdit) {
      return const SizedBox
          .shrink(); // user doesn't have the permission. disappear
    }
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => _menu(context, ref),
    );
  }

  List<PopupMenuEntry> _menu(BuildContext context, WidgetRef ref) {
    return [
      PopupMenuItem(
        onTap: () => setChildRoomSuggested(
          context,
          ref,
          parentId: parentId,
          roomId: childId,
          suggested: !isSuggested,
        ),
        child: Row(
          children: [
            Icon(isSuggested ? Icons.star : Icons.star_border_rounded),
            const SizedBox(width: 4),
            Text(isSuggested
                ? L10n.of(context).removeSuggested
                : L10n.of(context).addSuggested,),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () => unlinkChildRoom(
          context,
          ref,
          parentId: parentId,
          roomId: childId,
        ),
        child: Row(
          children: [const Icon(Icons.link_off), Text(L10n.of(context).unlink)],
        ),
      ),
    ];
  }
}
