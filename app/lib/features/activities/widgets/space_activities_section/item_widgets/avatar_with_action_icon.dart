import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';

class AvatarWithActionIcon extends StatelessWidget {
  final AvatarInfo avatarInfo;
  final IconData actionIcon;
  final Color? actionIconBgColor;
  final Color? actionIconColor;
  const AvatarWithActionIcon({
    super.key,
    required this.avatarInfo,
    required this.actionIcon,
    this.actionIconBgColor,
    this.actionIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 22)),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                width: 1,
              ),
              color:
                  actionIconBgColor?.withValues(alpha: 0.8) ??
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ),
            child: Icon(
              actionIcon,
              color: actionIconColor ?? Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
