import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceNotificationConfigurationPage extends ConsumerWidget {
  final String spaceId;

  const SpaceNotificationConfigurationPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: SpaceSettingsMenu(
        spaceId: spaceId,
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(L10n.of(context).spaceNotifications)),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(L10n.of(context).general),
              tiles: [
                NotificationsSettingsTile(
                  roomId: spaceId,
                  title: L10n.of(context).spaceNotificationOverwrite,
                  defaultTitle: L10n.of(context).noOverwrite,
                  includeMentions: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
