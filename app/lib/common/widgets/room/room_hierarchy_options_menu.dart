import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/actions/set_child_room_suggested.dart';
import 'package:acter/features/link_room/actions/unlink_child_room.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final membership = ref.watch(roomMembershipProvider(parentId)).valueOrNull;
    final canEdit = membership?.canString('CanLinkSpaces') == true;
    if (!canEdit) {
      // user doesn’t have the permission. disappear
      return const SizedBox.shrink();
    }
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => _menu(context, ref),
    );
  }

  List<PopupMenuEntry> _menu(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
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
            Text(isSuggested ? lang.removeSuggested : lang.addSuggested),
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
          children: [
            const Icon(Icons.link_off),
            Text(lang.unlink),
          ],
        ),
      ),
    ];
  }
}
