import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;
    bool isSelected(Routes route) {
      debugPrint(
        '${route.route} $currentRoute, ${currentRoute == route.route}',
      );
      return currentRoute == route.route;
    }

    final shouldGoNotNamed = isDesktop || size.width > 770;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: false,
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('Account'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                title: const Text('Sessions'),
                description: const Text('Your active device sessions'),
                leading: const Icon(Atlas.key_monitor_thin),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingSessions.name)
                      : context.pushNamed(Routes.settingSessions.name);
                },
              ),
              SettingsTile.navigation(
                title: const Text('Blocked Users'),
                description: const Text('Users you blocked'),
                leading: const Icon(Atlas.users_thin),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingSessions.name)
                      : context.pushNamed(Routes.settingSessions.name);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Acter App'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                title: const Text('Labs'),
                description: const Text('Experimental Acter features'),
                leading: const Icon(Atlas.lab_appliance_thin),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingsLabs.name)
                      : context.pushNamed(Routes.settingsLabs.name);
                },
              ),
              SettingsTile(
                title: const Text('Info'),
                leading: const Icon(Atlas.info_circle_thin),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.info.name)
                      : context.pushNamed(Routes.info.name);
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(
              'Danger Zone',
              style: TextStyle(
                color: AppTheme.brandColorScheme.error,
                backgroundColor: AppTheme.brandColorScheme.onError,
              ),
            ),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                title: const Text('Logout'),
                description:
                    const Text('Close this session, deleting local data'),
                leading: const Icon(Atlas.exit_thin),
                onPressed: (context) {
                  logoutConfirmationDialog(context, ref);
                },
              ),
              SettingsTile.navigation(
                title: Text(
                  'Deactivate Account',
                  style: TextStyle(
                    color: AppTheme.brandColorScheme.error,
                    //backgroundColor: AppTheme.brandColorScheme.onError,
                  ),
                ),
                description: Text(
                  'Irreversibly deactivate this account',
                  style: TextStyle(
                    color: AppTheme.brandColorScheme.error,
                  ),
                ),
                leading: Icon(
                  Atlas.trash_can_thin,
                  color: AppTheme.brandColorScheme.error,
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingSessions.name)
                      : context.pushNamed(Routes.settingSessions.name);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
