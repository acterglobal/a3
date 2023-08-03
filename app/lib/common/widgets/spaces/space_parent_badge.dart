import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceParentBadge extends ConsumerWidget {
  final String spaceId;
  final Widget child;
  final double badgeSize;
  const SpaceParentBadge({
    super.key,
    required this.spaceId,
    required this.child,
    this.badgeSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canonicalParent = ref.watch(canonicalParentProvider(spaceId));
    return Wrap(
      direction: Axis.horizontal,
      spacing: -(badgeSize / 2),
      children: [
        child,
        canonicalParent.when(
          data: (parent) {
            if (parent == null) {
              return const SizedBox.shrink();
            }
            return Column(
              children: <Widget>[
                SizedBox(height: badgeSize * 1.25),
                Tooltip(
                  message: parent.profile.displayName,
                  child: InkWell(
                    onTap: () {
                      final roomId = parent.space.getRoomId();
                      context.pushNamed('/$roomId');
                    },
                    child: ActerAvatar(
                      mode: DisplayMode.Space,
                      displayName: parent.profile.displayName,
                      uniqueId: parent.space.getRoomId().toString(),
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
      ],
    );
  }
}
