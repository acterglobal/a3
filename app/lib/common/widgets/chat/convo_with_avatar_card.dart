import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ConvoWithAvatarInfoCard extends ConsumerWidget {
  final String roomId;
  final AvatarInfo avatarInfo;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? avatar;
  final bool showSelectedIndication;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback? onLongPress;

  /// {@macro flutter.material.inkwell.onFocusChange}
  final ValueChanged<bool>? onFocusChange;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback? onTap;

  /// Whether or not to render the parent Icon
  ///
  final bool showParents;

  const ConvoWithAvatarInfoCard({
    super.key,
    required this.roomId,
    required this.avatarInfo,
    this.avatar,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.subtitle,
    this.trailing,
    this.showParents = true,
    this.showSelectedIndication = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(roomDisplayNameProvider(roomId));
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: onTap,
                selected: showSelectedIndication &&
                    roomId == ref.watch(selectedChatIdProvider),
                selectedTileColor: Theme.of(context).colorScheme.primary,
                onFocusChange: onFocusChange,
                onLongPress: onLongPress,
                leading: avatarWithIndicator(context, ref),
                title: displayName.when(
                  data: (dpl) => Text(
                    dpl ?? roomId,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  error: (error, stackTrace) => Text(
                    roomId,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  loading: () => Skeletonizer(
                    child: Text(
                      roomId,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                subtitle: constraints.maxWidth < 300 ? null : subtitle,
                trailing: constraints.maxWidth < 300 ? null : trailing,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget avatarWithIndicator(BuildContext context, WidgetRef ref) {
    final unreadCounters =
        ref.watch(unreadCountersProvider(roomId)).valueOrNull;

    final child =
        avatar ?? RoomAvatar(roomId: roomId, showParents: showParents);
    if (unreadCounters == null) {
      return child;
    }

    if (unreadCounters.$1 > 0) {
      return Badge(
        backgroundColor: Theme.of(context).colorScheme.badgeImportant,
        child: child,
      );
    } else if (unreadCounters.$2 > 0) {
      return Badge(
        backgroundColor: Theme.of(context).colorScheme.badgeUrgent,
        child: child,
      );
    } else if (unreadCounters.$3 > 0) {
      return Badge(
        backgroundColor: Theme.of(context).colorScheme.badgeUnread,
        child: child,
      );
    }
    // nothing urgent enough for us to indicate anything
    return child;
  }
}
