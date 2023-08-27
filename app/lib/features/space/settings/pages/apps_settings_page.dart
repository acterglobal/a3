import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';

class SpaceAppsSettingsPage extends StatelessWidget {
  final String spaceId;
  const SpaceAppsSettingsPage({Key? key, required this.spaceId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WithSidebar(
      child: Text('here comes the sun'),
      sidebar: SpaceSettingsMenu(
        spaceId: spaceId,
      ),
    );
  }
}
