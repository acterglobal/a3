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
          right: -6,
          bottom: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: actionIconBgColor ?? Theme.of(context).cardColor,
            ),
            child: Icon(
              actionIcon,
              color: actionIconColor ?? Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }
}
