import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceChip extends ConsumerWidget {
  final SpaceItem? space;
  final String? spaceId;

  const SpaceChip({
    Key? key,
    this.space,
    this.spaceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (space == null) {
      if (spaceId == null) {
        throw 'space or spaceId must be provided';
      }
      final brief = ref.watch(briefSpaceItemProvider(spaceId!));
      return brief.when(
        data: (space) => renderSpace(space),
        error: (error, st) => Chip(
          label: Text('Loading failed: $error'),
        ),
        loading: () => const Chip(
          label: Text('loading'),
        ),
      );
    }
    return renderSpace(space!);
  }

  Widget renderSpace(space) {
    return Chip(
      avatar: ActerAvatar(
        mode: DisplayMode.Space,
        avatarInfo: AvatarInfo(
          uniqueId: space.roomId,
          displayName: space.spaceProfileData.displayName,
          avatar: space.spaceProfileData.getAvatarImage(),
        ),
        size: 24,
      ),
      label: Text(space.spaceProfileData.displayName ?? space.roomId),
    );
  }
}
