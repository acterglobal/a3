import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/space/settings/widgets/space_settings_menu.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SpaceNotificationConfigurationPage extends ConsumerWidget {
  final String spaceId;

  const SpaceNotificationConfigurationPage({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: SpaceSettingsMenu(spaceId: spaceId),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.spaceNotifications),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(lang.general),
              tiles: [
                NotificationsSettingsTile(
                  roomId: spaceId,
                  title: lang.spaceNotificationOverwrite,
                  defaultTitle: lang.noOverwrite,
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
