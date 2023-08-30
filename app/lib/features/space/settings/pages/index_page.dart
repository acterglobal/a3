import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';

class SpaceSettingsMenuIndexPage extends StatelessWidget {
  final String spaceId;
  const SpaceSettingsMenuIndexPage({Key? key, required this.spaceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpaceSettingsMenu(
      spaceId: spaceId,
    );
  }
}
