import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/device_permissions/calendar.dart';
import 'package:acter/common/utils/device_permissions/notification.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final isBackupEnabled = ref.watch(
      isActiveProvider(LabsFeature.encryptionBackup),
    );
    final helpCenterUrl = helpUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  context.pushReplacementNamed(
                    Routes.settingsSuperInvites.name,
                  );
                } else {
                  context.pushNamed(Routes.settingsSuperInvites.name);
                }
              },
            ),
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: lang.behaviorSettingsTitle,
          children: [
            MenuItemWidget(
              iconData: Atlas.language_translation,
              title: lang.language,
              iconColor: routedColor(context, ref, Routes.settingLanguage),
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
              iconData: Atlas.bell_mobile_thin,
              iconColor: routedColor(context, ref, Routes.settingNotifications),
              title: lang.notifications,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingNotifications),
              ),
              onTap: () async {
                final hasPermission = await handleNotificationPermission(
                  context,
                );
                if (hasPermission && context.mounted) {
                  if (!isFullPage && context.isLargeScreen) {
                    context.pushReplacementNamed(
                      Routes.settingNotifications.name,
                    );
                  } else {
                    context.pushNamed(Routes.settingNotifications.name);
                  }
                }
              },
            ),
            MenuItemWidget(
              iconData: PhosphorIconsThin.chat,
              iconColor: routedColor(context, ref, Routes.settingsChat),
              title: lang.chat,
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
              iconData: PhosphorIconsThin.calendar,
              iconColor: routedColor(context, ref, Routes.settingsCalendar),
              title: lang.calendar,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsCalendar),
              ),
              onTap: () async {
                final hasPermission = await handleCalendarPermission(
                  context,
                );
                if (hasPermission && context.mounted) {
                  if (!isFullPage && context.isLargeScreen) {
                    context.pushReplacementNamed(Routes.settingsCalendar.name);
                  } else {
                    context.pushNamed(Routes.settingsCalendar.name);
                  }
                }
              
              },
            ),
            MenuItemWidget(
              iconData: PhosphorIconsThin.faders,
              iconColor: routedColor(
                context,
                ref,
                Routes.settingsCustomizations,
              ),
              title: lang.customizationsTitle,
              titleStyles: TextStyle(
                color: routedColor(context, ref, Routes.settingsCustomizations),
              ),
              onTap: () {
                if (!isFullPage && context.isLargeScreen) {
                  context.pushReplacementNamed(
                    Routes.settingsCustomizations.name,
                  );
                } else {
                  context.pushNamed(Routes.settingsCustomizations.name);
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
          ],
        ),
        _settingMenuSection(
          context: context,
          sectionTitle: lang.acter,
          children: [
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
              iconColor: colorScheme.error,
              title: lang.logOut,
              subTitle: lang.closeSessionAndDeleteData,
              titleStyles: TextStyle(color: colorScheme.error),
              onTap: () => logoutConfirmationDialog(context, ref),
            ),
            MenuItemWidget(
              key: SettingsMenu.deactivateAccount,
              iconData: Atlas.trash_can_thin,
              iconColor: colorScheme.error,
              title: lang.deactivateAccount,
              subTitle: lang.irreversiblyDeactivateAccount,
              titleStyles: TextStyle(color: colorScheme.error),
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 10),
            child: Text(
              sectionTitle,
              style: textTheme.labelLarge?.copyWith(
                color: isDanderZone ? colorScheme.error : null,
              ),
            ),
          ),
          Column(children: children),
        ],
      ),
    );
  }
}
