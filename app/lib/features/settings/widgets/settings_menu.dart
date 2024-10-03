import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const defaultSettingsMenuKey = Key('settings-menu');
final helpUrl = Uri.tryParse(Env.helpCenterUrl);

class SettingsMenu extends ConsumerWidget {
  static Key deactivateAccount = const Key('settings-auth-deactivate-account');
  static Key logoutAccount = const Key('settings-auth-logout-account');
  static Key superInvitations = const Key('settings-super-invitations');
  static Key emailAddresses = const Key('settings-email-addresses');
  static Key chat = const Key('settings-chat');
  static Key labs = const Key('settings-labs');

  final bool isFullPage;

  const SettingsMenu({
    this.isFullPage = false,
    super.key = defaultSettingsMenuKey,
  });

  Color? routedColor(BuildContext context, WidgetRef ref, Routes route) {
    final currentRoute = ref.watch(currentRoutingLocation);
    if (currentRoute != route.route) return null;
    return Theme.of(context).colorScheme.secondary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBackupEnabled =
        ref.watch(featuresProvider).isActive(LabsFeature.encryptionBackup);
    final helpMenuUrl = helpUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).account,
          children: [
            MenuItemWidget(
              iconData: Atlas.bell_mobile_thin,
              iconColor: routedColor(context, ref, Routes.settingNotifications),
              title: L10n.of(context).notifications,
              subTitle: L10n.of(context).notificationsSettingsAndTargets,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingNotifications),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context
                      .pushReplacementNamed(Routes.settingNotifications.name);
                } else {
                  context.pushNamed(Routes.settingNotifications.name);
                }
              },
            ),
            MenuItemWidget(
              innerKey: SettingsMenu.emailAddresses,
              iconData: Atlas.envelope_paper_email_thin,
              iconColor: routedColor(context, ref, Routes.emailAddresses),
              title: L10n.of(context).emailAddresses,
              subTitle: L10n.of(context).connectedToYourAccount,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.emailAddresses),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.emailAddresses.name);
                } else {
                  context.pushNamed(Routes.emailAddresses.name);
                }
              },
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).securityAndPrivacy,
          children: [
            MenuItemWidget(
              iconData: Atlas.key_monitor_thin,
              iconColor: routedColor(context, ref, Routes.settingSessions),
              title: L10n.of(context).sessions,
              subTitle: L10n.of(context).yourActiveDevices,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingSessions),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.settingSessions.name);
                } else {
                  context.pushNamed(Routes.settingSessions.name);
                }
              },
            ),
            if (isBackupEnabled)
              MenuItemWidget(
                iconData: Atlas.key_website_thin,
                iconColor: routedColor(context, ref, Routes.settingBackup),
                title: L10n.of(context).settingsKeyBackUpTitle,
                subTitle: L10n.of(context).settingsKeyBackUpDesc,
                titleStyles: TextStyle(
                  color: routedColor(context, ref, Routes.settingBackup),
                ),
                onTap: () {
                  if (!isFullPage && context.isLargeScreen) {
                    context.pushReplacementNamed(Routes.settingBackup.name);
                  } else {
                    context.pushNamed(Routes.settingBackup.name);
                  }
                },
              ),
            MenuItemWidget(
              iconData: Atlas.users_thin,
              iconColor: routedColor(context, ref, Routes.blockedUsers),
              title: L10n.of(context).blockedUsers,
              subTitle: L10n.of(context).usersYouBlocked,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.blockedUsers),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.blockedUsers.name);
                } else {
                  context.pushNamed(Routes.blockedUsers.name);
                }
              },
            ),
            MenuItemWidget(
              iconData: Atlas.passcode,
              iconColor: routedColor(context, ref, Routes.changePassword),
              title: L10n.of(context).changePassword,
              subTitle: L10n.of(context).changePasswordDescription,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.changePassword),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.changePassword.name);
                } else {
                  context.pushNamed(Routes.changePassword.name);
                }
              },
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).community,
          children: [
            MenuItemWidget(
              innerKey: SettingsMenu.superInvitations,
              iconData: Atlas.plus_envelope_thin,
              enabled: ref.watch(hasSuperTokensAccess).valueOrNull == true,
              iconColor: routedColor(context, ref, Routes.settingsSuperInvites),
              title: L10n.of(context).superInvitations,
              subTitle: L10n.of(context).manageYourInvitationCodes,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsSuperInvites),
              ),
              onTap: () {
                if (ref.read(hasSuperTokensAccess).valueOrNull != true) return;
                if (!isFullPage && context.isLargeScreen) {
                  context
                      .pushReplacementNamed(Routes.settingsSuperInvites.name);
                } else {
                  context.pushNamed(Routes.settingsSuperInvites.name);
                }
              },
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).acterApp,
          children: [
            MenuItemWidget(
              key: SettingsMenu.chat,
              iconData: Atlas.chat_conversation_thin,
              iconColor: routedColor(context, ref, Routes.settingsChat),
              title: L10n.of(context).chat,
              subTitle: L10n.of(context).chatSettingsExplainer,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsChat),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.settingsChat.name);
                } else {
                  context.pushNamed(Routes.settingsChat.name);
                }
              },
            ),
            MenuItemWidget(
              iconData: Atlas.language_translation,
              iconColor: routedColor(context, ref, Routes.settingLanguage),
              title: L10n.of(context).language,
              subTitle: L10n.of(context).changeAppLanguage,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingLanguage),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.settingLanguage.name);
                } else {
                  context.pushNamed(Routes.settingLanguage.name);
                }
              },
            ),
            MenuItemWidget(
              key: SettingsMenu.labs,
              iconData: Atlas.lab_appliance_thin,
              iconColor: routedColor(context, ref, Routes.settingsLabs),
              title: L10n.of(context).labs,
              subTitle: L10n.of(context).experimentalActerFeatures,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsLabs),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.settingsLabs.name);
                } else {
                  context.pushNamed(Routes.settingsLabs.name);
                }
              },
            ),
            MenuItemWidget(
              iconData: Atlas.info_circle_thin,
              iconColor: routedColor(context, ref, Routes.info),
              title: L10n.of(context).info,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.info),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(Routes.info.name);
                } else {
                  context.pushNamed(Routes.info.name);
                }
              },
            ),
            if (helpMenuUrl != null)
              MenuItemWidget(
                iconData: PhosphorIcons.question(),
                title: L10n.of(context).helpCenterTitle,
                subTitle: L10n.of(context).helpCenterDesc,
                trailing: Icon(PhosphorIcons.arrowSquareOut()),
                onTap: () => launchUrl(helpMenuUrl),
              ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: L10n.of(context).dangerZone,
          isDanderZone: true,
          children: [
            MenuItemWidget(
              key: SettingsMenu.logoutAccount,
              iconData: Atlas.exit_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: L10n.of(context).logOut,
              subTitle: L10n.of(context).closeSessionAndDeleteData,
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => logoutConfirmationDialog(context, ref),
            ),
            MenuItemWidget(
              key: SettingsMenu.deactivateAccount,
              iconData: Atlas.trash_can_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: L10n.of(context).deactivateAccount,
              subTitle: L10n.of(context).irreversiblyDeactivateAccount,
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
          Column(children: children),
        ],
      ),
    );
  }
}
