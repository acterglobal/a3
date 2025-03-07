import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';

class SpaceSettingsMenuIndexPage extends StatelessWidget {
  final String spaceId;
  const SpaceSettingsMenuIndexPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context) {
    return SpaceSettingsMenu(spaceId: spaceId, isFullPage: true);
  }
}
