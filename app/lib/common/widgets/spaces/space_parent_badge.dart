import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceParentBadge extends ConsumerWidget {
  final String spaceId;
  final Widget child;
  final double badgeSize;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;
  const SpaceParentBadge({
    super.key,
    required this.spaceId,
    required this.child,
    this.onTap,
    this.badgeSize = 25,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canonicalParent = ref.watch(canonicalParentProvider(spaceId));
    final badgeOverflow = badgeSize / 3;
    return Padding(
      padding: EdgeInsets.only(right: badgeOverflow, bottom: badgeOverflow),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          child,
          Positioned(
            bottom: -badgeOverflow,
            right: -badgeOverflow,
            child: canonicalParent.when(
              data: (parent) {
                if (parent == null) {
                  return const SizedBox.shrink();
                }
                final parentId = parent.space.getRoomIdStr();
                return Column(
                  children: <Widget>[
                    SizedBox(height: badgeSize * 1.25),
                    Tooltip(
                      message: parent.profile.displayName,
                      child: InkWell(
                        onTap: onTap ??
                            () {
                              context.push('/$parentId');
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
              error: (error, stackTrace) => Text(
                'Failed to load canonical parent due to $error',
              ),
              loading: () => const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
