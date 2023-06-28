import 'package:flutter/material.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/features/space/providers/space_providers.dart';

class SpaceChip extends StatelessWidget {
  final SpaceItem space;
  const SpaceChip({Key? key, required this.space}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: ActerAvatar(
        mode: DisplayMode.Space,
        displayName: space.spaceProfileData.displayName,
        uniqueId: space.roomId,
        avatar: space.spaceProfileData.getAvatarImage(),
        size: 24,
      ),
      label: Text(space.spaceProfileData.displayName ?? space.roomId),
    );
  }
}
