import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;
    Color? colorSelected(Routes route) => currentRoute == route.route
        ? AppTheme.brandColorScheme.secondary
        : null;

    TextStyle titleStylesSelected(Routes route) {
      return TextStyle(
        color: colorSelected(route),
      );
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
                title: Text(
                  'Sessions',
                  style: titleStylesSelected(Routes.settingSessions),
                ),
                description: Text(
                  'Your active device sessions',
                  style: titleStylesSelected(Routes.settingSessions),
                ),
                leading: Icon(
                  Atlas.key_monitor_thin,
                  color: colorSelected(Routes.settingSessions),
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingSessions.name)
                      : context.pushNamed(Routes.settingSessions.name);
                },
              ),
              SettingsTile.navigation(
                title: Text(
                  'Email Addresses',
                  style: titleStylesSelected(Routes.emailAddresses),
                ),
                description: Text(
                  'Connected to your account',
                  style: titleStylesSelected(Routes.emailAddresses),
                ),
                leading: Icon(
                  Atlas.envelope_paper_email_thin,
                  color: colorSelected(Routes.emailAddresses),
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.emailAddresses.name)
                      : context.pushNamed(Routes.emailAddresses.name);
                },
              ),
              SettingsTile.navigation(
                title: Text(
                  'Notifications',
                  style: titleStylesSelected(Routes.settingNotifications),
                ),
                description: Text(
                  'Notifications settings and targets',
                  style: titleStylesSelected(Routes.settingNotifications),
                ),
                leading: Icon(
                  Atlas.bell_mobile_thin,
                  color: colorSelected(Routes.settingNotifications),
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingNotifications.name)
                      : context.pushNamed(Routes.settingNotifications.name);
                },
              ),
              SettingsTile.navigation(
                title: Text(
                  'Blocked Users',
                  style: titleStylesSelected(Routes.blockedUsers),
                ),
                description: Text(
                  'Users you blocked',
                  style: titleStylesSelected(Routes.blockedUsers),
                ),
                leading: Icon(
                  Atlas.users_thin,
                  color: colorSelected(Routes.blockedUsers),
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.blockedUsers.name)
                      : context.pushNamed(Routes.blockedUsers.name);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('Acter App'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                title: Text(
                  'Labs',
                  style: titleStylesSelected(Routes.settingsLabs),
                ),
                description: Text(
                  'Experimental Acter features',
                  style: titleStylesSelected(Routes.settingsLabs),
                ),
                leading: Icon(
                  Atlas.lab_appliance_thin,
                  color: colorSelected(Routes.settingsLabs),
                ),
                onPressed: (context) {
                  shouldGoNotNamed
                      ? context.goNamed(Routes.settingsLabs.name)
                      : context.pushNamed(Routes.settingsLabs.name);
                },
              ),
              SettingsTile(
                title: Text('Info', style: titleStylesSelected(Routes.info)),
                leading: Icon(
                  Atlas.info_circle_thin,
                  color: colorSelected(Routes.info),
                ),
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
