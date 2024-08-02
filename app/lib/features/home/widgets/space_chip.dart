import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::home::space_chip');

class SpaceChip extends ConsumerWidget {
  final SpaceItem? space;
  final String? spaceId;
  final bool onTapOpenSpaceDetail;

  const SpaceChip({
    super.key,
    this.space,
    this.spaceId,
    this.onTapOpenSpaceDetail = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (space == null) {
      if (spaceId == null) {
        throw L10n.of(context).spaceOrSpaceIdMustBeProvided;
      }
      final brief = ref.watch(briefSpaceItemProvider(spaceId!));
      return brief.when(
        data: (space) {
          return renderSpace(context, space);
        },
        error: (error, st) {
          _log.severe('Fetching of brief space item failed', error, st);
          return Chip(
            label: Text(L10n.of(context).loadingFailed(error)),
          );
        },
        loading: () => renderLoading(spaceId!),
      );
    }
    return renderSpace(context, space!);
  }

  Widget renderLoading(String spaceId) {
    return Skeletonizer(
      child: Chip(
        avatar: ActerAvatar(
          options: AvatarOptions(
            AvatarInfo(uniqueId: spaceId),
            size: 24,
          ),
        ),
        label: Text(spaceId),
      ),
    );
  }

  Widget renderSpace(BuildContext context, SpaceItem space) {
    return InkWell(
      onTap:
          onTapOpenSpaceDetail ? () => goToSpace(context, space.roomId) : null,
      child: Chip(
        avatar: ActerAvatar(
          options: AvatarOptions(
            AvatarInfo(
              uniqueId: space.roomId,
              displayName: space.avatarInfo.displayName,
              avatar: space.avatarInfo.avatar,
            ),
            size: 24,
          ),
        ),
        label: Text(space.avatarInfo.displayName ?? space.roomId),
      ),
    );
  }
}
