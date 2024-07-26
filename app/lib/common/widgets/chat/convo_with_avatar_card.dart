import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ConvoWithAvatarInfoCard extends ConsumerWidget {
  final String roomId;
  final AvatarInfo avatarInfo;
  final Widget? subtitle;
  final Widget? trailing;
  final Widget? avatar;
  final bool showSelectedIndication;
  final Animation<double>? animation;

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

  /// Whether or not to render the suggested Icon
  ///
  final bool showSuggestedMark;

  const ConvoWithAvatarInfoCard({
    super.key,
    required this.roomId,
    required this.avatarInfo,
    this.animation,
    this.avatar,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.subtitle,
    this.trailing,
    this.showSuggestedMark = false,
    this.showParents = true,
    this.showSelectedIndication = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (animation != null) {
      return SizeTransition(
        sizeFactor: animation!,
        child: buildInner(context, ref),
      );
    }
    return buildInner(context, ref);
  }

  Widget buildInner(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                onTap: onTap,
                selected: showSelectedIndication &&
                    roomId == ref.watch(selectedChatIdProvider),
                selectedTileColor: Theme.of(context).colorScheme.primary,
                onFocusChange: onFocusChange,
                onLongPress: onLongPress,
                leading: avatarWithIndicator(context, ref),
                title: Text(
                  avatarInfo.displayName ?? roomId,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: buildSubtitle(context, constraints),
                trailing: constraints.maxWidth < 300 ? null : trailing,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? buildSubtitle(BuildContext context, BoxConstraints constraints) {
    if (!showSuggestedMark) {
      return constraints.maxWidth < 300 ? null : subtitle;
    }

    if (subtitle != null) {
      return Row(
        children: [
          Text(
            L10n.of(context).suggested,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 2),
          Expanded(child: subtitle!),
        ],
      );
    }

    return Text(
      L10n.of(context).suggested,
      style: Theme.of(context).textTheme.labelSmall,
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
