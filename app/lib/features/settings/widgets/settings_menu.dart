import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
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
    if (currentRoute == route.route) {
      return Theme.of(context).colorScheme.secondary;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final isBackupEnabled =
        ref.watch(isActiveProvider(LabsFeature.encryptionBackup));
    final helpCenterUrl = helpUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _settingMenuSection(
          context: context,
          sectionTitle: lang.account,
          children: [
            MenuItemWidget(
              iconData: Atlas.bell_mobile_thin,
              iconColor: routedColor(context, ref, Routes.settingNotifications),
              title: lang.notifications,
              subTitle: lang.notificationsSettingsAndTargets,
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
              title: lang.emailAddresses,
              subTitle: lang.connectedToYourAccount,
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
          sectionTitle: lang.securityAndPrivacy,
          children: [
            MenuItemWidget(
              iconData: Atlas.key_monitor_thin,
              iconColor: routedColor(context, ref, Routes.settingSessions),
              title: lang.sessions,
              subTitle: lang.yourActiveDevices,
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
                title: lang.settingsKeyBackUpTitle,
                subTitle: lang.settingsKeyBackUpDesc,
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
              title: lang.blockedUsers,
              subTitle: lang.usersYouBlocked,
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
              title: lang.changePassword,
              subTitle: lang.changePasswordDescription,
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
          sectionTitle: lang.community,
          children: [
            MenuItemWidget(
              innerKey: SettingsMenu.superInvitations,
              iconData: Atlas.plus_envelope_thin,
              enabled: ref.watch(hasSuperTokensAccess).valueOrNull == true,
              iconColor: routedColor(context, ref, Routes.settingsSuperInvites),
              title: lang.superInvitations,
              subTitle: lang.manageYourInvitationCodes,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsSuperInvites),
              ),
              onTap: () async {
                final hasAccess = await ref.read(hasSuperTokensAccess.future);
                if (!hasAccess) return;
                if (!context.mounted) return;
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
          sectionTitle: lang.acterApp,
          children: [
            MenuItemWidget(
              key: SettingsMenu.chat,
              iconData: Atlas.chat_conversation_thin,
              iconColor: routedColor(context, ref, Routes.settingsChat),
              title: lang.chat,
              subTitle: lang.chatSettingsExplainer,
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
              title: lang.language,
              subTitle: lang.changeAppLanguage,
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
              title: lang.labs,
              subTitle: lang.experimentalActerFeatures,
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
              title: lang.info,
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
            if (helpCenterUrl != null)
              MenuItemWidget(
                iconData: PhosphorIcons.question(),
                title: lang.helpCenterTitle,
                subTitle: lang.helpCenterDesc,
                trailing: Icon(PhosphorIcons.arrowSquareOut()),
                onTap: () => launchUrl(helpCenterUrl),
              ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: lang.dangerZone,
          isDanderZone: true,
          children: [
            MenuItemWidget(
              key: SettingsMenu.logoutAccount,
              iconData: Atlas.exit_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: lang.logOut,
              subTitle: lang.closeSessionAndDeleteData,
              titleStyles: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => logoutConfirmationDialog(context, ref),
            ),
            MenuItemWidget(
              key: SettingsMenu.deactivateAccount,
              iconData: Atlas.trash_can_thin,
              iconColor: Theme.of(context).colorScheme.error,
              title: lang.deactivateAccount,
              subTitle: lang.irreversiblyDeactivateAccount,
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
            padding: const EdgeInsets.only(
              left: 15,
              top: 10,
            ),
            child: Text(
              sectionTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
