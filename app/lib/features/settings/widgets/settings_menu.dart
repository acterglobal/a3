import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  static Key deactivateAccount = const Key('settings-auth-deactivate-account');
  static Key logoutAccount = const Key('settings-auth-logout-account');
  static Key superInvitations = const Key('settings-super-invitations');
  static Key labs = const Key('settings-labs');

  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;

    Color? colorSelected(Routes route) => currentRoute == route.route
        ? AppTheme.brandColorScheme.secondary
        : null;

    TextStyle titleStylesSelected(Routes route) {
      return TextStyle(color: colorSelected(route));
    }

    final shouldGoNotNamed = isDesktop && size.width > 770;

    final isSuperInviteEnable =
        ref.watch(hasSuperTokensAccess).valueOrNull == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _settingMenuSection(
          context: context,
          sectionTitle: 'Account',
          children: [
            _settingMenuItem(
              context: context,
              iconData: Atlas.key_monitor_thin,
              iconColor: colorSelected(Routes.settingSessions),
              title: 'Sessions',
              subTitle: 'Your active device sessions',
              titleStyles: titleStylesSelected(Routes.settingSessions),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingSessions.name)
                  : context.pushNamed(Routes.settingSessions.name),
            ),
            _settingMenuItem(
              context: context,
              iconData: Atlas.bell_mobile_thin,
              iconColor: colorSelected(Routes.settingNotifications),
              title: 'Notifications',
              subTitle: 'Notifications settings and targets',
              titleStyles: titleStylesSelected(Routes.settingNotifications),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingNotifications.name)
                  : context.pushNamed(Routes.settingNotifications.name),
            ),
            _settingMenuItem(
              context: context,
              iconData: Atlas.envelope_paper_email_thin,
              iconColor: colorSelected(Routes.emailAddresses),
              title: 'Email Addresses',
              subTitle: 'Connected to your account',
              titleStyles: titleStylesSelected(Routes.emailAddresses),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.emailAddresses.name)
                  : context.pushNamed(Routes.emailAddresses.name),
            ),
            _settingMenuItem(
              context: context,
              iconData: Atlas.users_thin,
              iconColor: colorSelected(Routes.blockedUsers),
              title: 'Blocked Users',
              subTitle: 'Users you blocked',
              titleStyles: titleStylesSelected(Routes.blockedUsers),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.blockedUsers.name)
                  : context.pushNamed(Routes.blockedUsers.name),
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: 'Community',
          children: [
            _settingMenuItem(
              key: SettingsMenu.superInvitations,
              context: context,
              iconData: Atlas.plus_envelope_thin,
              enable: isSuperInviteEnable,
              iconColor: colorSelected(Routes.settingsSuperInvites),
              title: 'Super Invitations',
              subTitle: 'Manage your invitation codes',
              titleStyles: titleStylesSelected(Routes.settingsSuperInvites),
              onTap: isSuperInviteEnable
                  ? () => shouldGoNotNamed
                      ? context.goNamed(Routes.settingsSuperInvites.name)
                      : context.pushNamed(Routes.settingsSuperInvites.name)
                  : null,
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: 'Acter App',
          children: [
            _settingMenuItem(
              key: SettingsMenu.labs,
              context: context,
              iconData: Atlas.lab_appliance_thin,
              iconColor: colorSelected(Routes.settingsLabs),
              title: 'Labs',
              subTitle: 'Experimental Acter features',
              titleStyles: titleStylesSelected(Routes.settingsLabs),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.settingsLabs.name)
                  : context.pushNamed(Routes.settingsLabs.name),
            ),
            _settingMenuItem(
              context: context,
              iconData: Atlas.info_circle_thin,
              iconColor: colorSelected(Routes.info),
              title: 'Info',
              titleStyles: titleStylesSelected(Routes.info),
              onTap: () => shouldGoNotNamed
                  ? context.goNamed(Routes.info.name)
                  : context.pushNamed(Routes.info.name),
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: 'Danger Zone',
          isDanderZone: true,
          children: [
            _settingMenuItem(
              key: SettingsMenu.logoutAccount,
              context: context,
              iconData: Atlas.exit_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: 'Logout',
              subTitle: 'Close this session, deleting local data',
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => logoutConfirmationDialog(context, ref),
            ),
            _settingMenuItem(
              key: SettingsMenu.deactivateAccount,
              context: context,
              iconData: Atlas.trash_can_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: 'Deactivate Account',
              subTitle: 'Irreversibly deactivate this account',
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => deactivationConfirmationDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _settingMenuSection({
    required BuildContext context,
    required String sectionTitle,
    bool isDanderZone = false,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 10.0),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: isDanderZone
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
            ),
          ),
          Column(
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _settingMenuItem({
    Key? key,
    required BuildContext context,
    required IconData iconData,
    Color? iconColor,
    required String title,
    TextStyle? titleStyles,
    String? subTitle,
    VoidCallback? onTap,
    bool enable = true,
  }) {
    return Card(
      child: ListTile(
        key: key,
        onTap: onTap,
        leading: Icon(
          iconData,
          color: enable ? iconColor : Theme.of(context).disabledColor,
        ),
        title: Text(
          title,
          style: titleStyles?.copyWith(
            color: enable ? null : Theme.of(context).disabledColor,
          ),
        ),
        subtitle: subTitle == null
            ? null
            : Text(
                subTitle,
                style: titleStyles?.copyWith(
                  color: enable ? null : Theme.of(context).disabledColor,
                ),
              ),
        trailing: const Icon(
          Icons.keyboard_arrow_right_outlined,
        ),
      ),
    );
  }
}
