import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/link_room/providers/link_room_providers.dart';
import 'package:acter/features/link_room/widgets/link_room_trailing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkSpaceListItem extends ConsumerWidget {
  final String parentId;
  final String roomId;
  const LinkSpaceListItem({
    super.key,
    required this.parentId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (parentId: parentId, childId: roomId);
    final isSubspace = ref.watch(isSubSpaceProvider(query));
    final isRecommended = ref.watch(isRecommendedProvider(query));
    final isLinked = isSubspace || isRecommended;

    final subtitle = isSubspace
        ? Text(L10n.of(context).subspace)
        : isRecommended
            ? Text(L10n.of(context).recommendedSpace)
            : null;

    final roomName =
        ref.watch(roomDisplayNameProvider(roomId)).valueOrNull ?? roomId;

    return ListTile(
      key: Key('space-list-link-$roomId'),
      leading: RoomAvatarBuilder(
        roomId: roomId,
        avatarSize: 24,
      ),
      title: Text(roomName),
      subtitle: subtitle,
      trailing: LinkRoomTrailing(
        parentId: parentId,
        roomId: roomId,
        isLinked: isLinked,
        canLink: true,
      ),
    );
  }
}
