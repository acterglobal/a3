import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SpaceNotificationConfigurationPage extends ConsumerWidget {
  final String spaceId;
  const SpaceNotificationConfigurationPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: SpaceSettingsMenu(
        spaceId: spaceId,
      ),
      child: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('General'),
            tiles: [
              NotificationsSettingsTile(
                roomId: spaceId,
                title: 'Space-wide overwrite',
                defaultTitle: 'No Overwrite',
                includeMentions: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
