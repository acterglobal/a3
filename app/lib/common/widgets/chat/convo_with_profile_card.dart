import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConvoWithProfileCard extends ConsumerWidget {
  final String roomId;
  final ProfileData profile;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? avatar;

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

  const ConvoWithProfileCard({
    super.key,
    required this.roomId,
    required this.profile,
    this.avatar,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.subtitle,
    this.trailing,
    this.showParents = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: onTap,
                selected: roomId == ref.watch(selectedChatIdProvider),
                selectedTileColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                onFocusChange: onFocusChange,
                onLongPress: onLongPress,
                leading: avatarWithIndicator(context, ref),
                title: Text(
                  profile.displayName ?? roomId,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
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
