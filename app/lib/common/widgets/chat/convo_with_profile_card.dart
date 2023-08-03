import 'package:acter/common/models/profile_data.dart';
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
  const ConvoWithProfileCard({
    super.key,
    required this.roomId,
    required this.profile,
    this.onTap,
    this.onLongPress,
    this.onFocusChange,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          onTap: onTap,
          onFocusChange: onFocusChange,
          onLongPress: onLongPress,
          leading: ActerAvatar(
            uniqueId: roomId,
            mode: DisplayMode.GroupChat,
            displayName: profile.displayName ?? roomId,
            avatar: profile.getAvatarImage(),
            size: 36,
          ),
          title: Text(
            profile.displayName ?? roomId,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(fontWeight: FontWeight.w700),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle,
          trailing: trailing,
        ),
        Divider(
          indent: 75,
          endIndent: 10,
          color: Theme.of(context).colorScheme.tertiary,
        ),
      ],
    );
  }
}
