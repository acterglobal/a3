import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConvoWithProfileCard extends ConsumerWidget {
  final String roomId;
  final ProfileData profile;
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

  const ConvoWithProfileCard({
    super.key,
    required this.roomId,
    required this.profile,
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
      displayName: profile.displayName ?? roomId,
      avatar: profile.getAvatarImage(),
      size: 36,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              onTap: onTap,
              selected: roomId == ref.read(selectedChatIdProvider),
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
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
