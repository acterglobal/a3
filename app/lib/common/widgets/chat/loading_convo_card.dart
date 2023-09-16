import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingConvoCard extends ConsumerWidget {
  final String roomId;
  final Widget? subtitle;
  final Widget? trailing;

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
  final bool showParent;

  const LoadingConvoCard({
    super.key,
    required this.roomId,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.subtitle,
    this.trailing,
    this.showParent = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ActerAvatar(
      uniqueId: roomId,
      mode: DisplayMode.GroupChat,
      size: 36,
    );

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
                selectedTileColor: Theme.of(context).colorScheme.onPrimary,
                onFocusChange: onFocusChange,
                onLongPress: onLongPress,
                leading: showParent
                    ? SpaceParentBadge(
                        spaceId: roomId,
                        badgeSize: 20,
                        child: avatar,
                      )
                    : avatar,
                title: Text(
                  '',
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
            constraints.maxWidth < 300
                ? const SizedBox.shrink()
                : Divider(
                    indent: 75,
                    endIndent: 10,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
          ],
        );
      },
    );
  }
}
