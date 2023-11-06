import 'package:acter/common/providers/room_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final log = Logger('SpaceParentBadge');

class SpaceParentBadge extends ConsumerWidget {
  final String roomId;
  final Widget child;
  final double badgeSize;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;
  const SpaceParentBadge({
    super.key,
    required this.roomId,
    required this.child,
    this.onTap,
    this.badgeSize = 25,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canonicalParent = ref.watch(canonicalParentProvider(roomId));
    final badgeOverflow = badgeSize / 5;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child,
        Positioned(
          bottom: -badgeOverflow,
          right: -badgeOverflow,
          child: canonicalParent.when(
            data: (parent) {
              if (parent == null) {
                return SizedBox(height: badgeSize + badgeOverflow);
              }
              final parentId = parent.space.getRoomIdStr();
              return Column(
                children: <Widget>[
                  SizedBox(
                    width: badgeSize + badgeOverflow,
                    height: badgeSize + badgeOverflow,
                  ),
                  Tooltip(
                    message: parent.profile.displayName,
                    child: InkWell(
                      onTap: onTap ??
                          () {
                            context.go('/$parentId');
                          },
                      child: ActerAvatar(
                        mode: DisplayMode.Space,
                        displayName: parent.profile.displayName,
                        uniqueId: parentId,
                        avatar: parent.profile.getAvatarImage(),
                        size: badgeSize,
                      ),
                    ),
                  ),
                ],
              );
            },
            error: (error, stackTrace) {
              log.severe(
                'Failed to load canonical parent of $roomId',
                error,
                stackTrace,
              );
              return const SizedBox.shrink();
            },
            loading: () => const CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}
