import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/notifications_mode_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/app_notifications_settings_tile.dart';
import 'package:acter/features/settings/widgets/labs_notifications_settings_tile.dart';
import 'package:acter/features/settings/widgets/settings_section_with_title_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::settings::notifications_page');

class _AddEmail extends StatefulWidget {
  final List<String> emails;

  const _AddEmail(this.emails);

  @override
  State<_AddEmail> createState() => __AddEmailState();
}

class __AddEmailState extends State<_AddEmail> {
  String? emailAddr;

  @override
  void initState() {
    super.initState();
    emailAddr = widget.emails.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).emailAddressToAdd),
      content: DropdownMenu<String>(
        initialSelection: widget.emails.first,
        onSelected: (String? value) {
          // This is called when the user selects an item.
          setState(() {
            emailAddr = value!;
          });
        },
        dropdownMenuEntries:
            widget.emails.map<DropdownMenuEntry<String>>((String value) {
          return DropdownMenuEntry<String>(value: value, label: value);
        }).toList(),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () {
            Navigator.pop(context, emailAddr);
          },
          child: Text(L10n.of(context).add),
        ),
      ],
    );
  }
}

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).notifications),
        ),
        body: SettingsList(
          shrinkWrap: true,
          sections: [
            SettingsSection(
              title: Text(L10n.of(context).notifications),
              tiles: [
                LabsNotificationsSettingsTile(
                  title: L10n.of(context).pushToThisDevice,
                ),
                AppsNotificationsSettingsTile(
                  title: L10n.of(context).updates,
                  description: L10n.of(context).notifyAboutSpaceUpdates,
                  appKey: 'global.acter.dev.news',
                ),
              ],
            ),
            SettingsSection(
              title: Text(L10n.of(context).defaultModes),
              tiles: [
                _notifSection(
                  context,
                  ref,
                  L10n.of(context).regularSpaceOrChat,
                  false,
                  false,
                ),
                _notifSection(
                  context,
                  ref,
                  L10n.of(context).encryptedSpaceOrChat,
                  true,
                  false,
                ),
                _notifSection(
                  context,
                  ref,
                  L10n.of(context).dmChat,
                  false,
                  true,
                ),
                _notifSection(
                  context,
                  ref,
                  L10n.of(context).encryptedDMChat,
                  true,
                  true,
                ),
              ],
            ),
            _pushTargets(context, ref),
          ],
        ),
      ),
    );
  }

  SettingsTile _notifSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    bool isEncrypted,
    bool isOneToOne,
  ) {
    final curNotifStatus = ref
            .watch(
              currentNotificationModeProvider(
                (encrypted: isEncrypted, oneToOne: isOneToOne),
              ),
            )
            .valueOrNull ??
        '';
    return SettingsTile(
      title: Text(title),
      description: Text(
        notifToText(context, curNotifStatus) ?? '(${L10n.of(context).unset})',
      ),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (newMode) => _onNotifSectionChange(
          context,
          ref,
          isEncrypted,
          isOneToOne,
          newMode,
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'all',
            child: Text(L10n.of(context).allMessages),
          ),
          PopupMenuItem<String>(
            value: 'mentions',
            child: Text(L10n.of(context).mentionsAndKeywordsOnly),
          ),
          PopupMenuItem<String>(
            value: 'muted',
            child: Text(L10n.of(context).muted),
          ),
        ],
      ),
    );
  }

  Future<void> _onNotifSectionChange(
    BuildContext context,
    WidgetRef ref,
    bool isEncrypted,
    bool isOneToOne,
    String newMode,
  ) async {
    EasyLoading.show(status: L10n.of(context).changingNotificationMode);
    try {
      final notifier = ref.read(notificationSettingsProvider).valueOrNull!;
      await notifier.setDefaultNotificationMode(
        isEncrypted,
        isOneToOne,
        newMode,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).notificationStatusSubmitted);
    } catch (e, st) {
      _log.severe('Failed to update notification status', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).notificationStatusUpdateFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  SettingsSectionWithTitleActions _pushTargets(
    BuildContext context,
    WidgetRef ref,
  ) {
    final potentialEmails = ref.watch(possibleEmailToAddForPushProvider);
    return SettingsSectionWithTitleActions(
      title: Text(L10n.of(context).notificationTargets),
      actions: potentialEmails.maybeWhen(
        orElse: () => [],
        data: (emails) {
          if (emails.isEmpty) {
            return [];
          }
          return [
            IconButton(
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
              ),
              iconSize: 20,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () => _onTargetAdd(context, ref, emails),
            ),
          ];
        },
      ),
      tiles: ref.watch(pushersProvider).when(
            data: (items) {
              if (items.isEmpty) {
                return [
                  SettingsTile(
                    title: Text(L10n.of(context).noPushTargetsAddedYet),
                  ),
                ];
              }
              return items
                  .map((item) => _pusherTile(context, ref, item))
                  .toList();
            },
            error: (e, s) => [
              SettingsTile(
                title: Text(L10n.of(context).failedToLoadPushTargets(e)),
              ),
            ],
            loading: () => [
              SettingsTile(
                title: Text(L10n.of(context).loadingTargets),
              ),
            ],
          ),
    );
  }

  Future<void> _onTargetAdd(
    BuildContext context,
    WidgetRef ref,
    List<String> emails,
  ) async {
    final emailToAdd = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) => _AddEmail(emails),
    );
    if (!context.mounted) return;
    if (emailToAdd == null) return;
    EasyLoading.show(status: L10n.of(context).adding(emailToAdd));
    final client = ref.read(
      alwaysClientProvider,
    ); // is guaranteed because of the ignoredUsersProvider using it
    try {
      await client.addEmailPusher(
        appIdPrefix,
        (await deviceName()),
        emailToAdd,
        null,
      );
      ref.invalidate(possibleEmailToAddForPushProvider);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToAdd('$emailToAdd: $e'),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    ref.invalidate(pushersProvider);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(L10n.of(context).addedToPusherList(emailToAdd));
  }

  SettingsTile _pusherTile(BuildContext context, WidgetRef ref, Pusher item) {
    final isEmail = item.isEmailPusher();
    return SettingsTile(
      leading: Icon(isEmail ? Atlas.envelope : Atlas.mobile_portrait_thin),
      title: Text(isEmail ? item.pushkey() : item.deviceDisplayName()),
      description: isEmail ? null : Text(item.appDisplayName()),
      trailing: const Icon(Atlas.dots_vertical_thin),
      onPressed: (context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).pushTargetDetails),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text(L10n.of(context).appId),
                  subtitle: Text(item.appId()),
                ),
                ListTile(
                  title: Text(L10n.of(context).pushKey),
                  subtitle: Text(item.pushkey()),
                ),
                ListTile(
                  title: Text(L10n.of(context).appName),
                  subtitle: Text(item.appDisplayName()),
                ),
                ListTile(
                  title: Text(L10n.of(context).deviceName),
                  subtitle: Text(item.deviceDisplayName()),
                ),
                ListTile(
                  title: Text(L10n.of(context).language),
                  subtitle: Text(item.lang()),
                ),
              ],
            ),
            // alert dialog with details;
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(L10n.of(context).closeDialog),
            ),
            ActerDangerActionButton(
              onPressed: () => _onTargetDelete(context, ref, item),
              child: Text(
                L10n.of(context).deleteTarget,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTargetDelete(
    BuildContext context,
    WidgetRef ref,
    Pusher item,
  ) async {
    Navigator.pop(context, null);
    EasyLoading.show(status: L10n.of(context).deletingPushTarget);
    try {
      await item.delete();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).pushTargetDeleted);
      ref.invalidate(possibleEmailToAddForPushProvider);
      ref.invalidate(pushersProvider);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).deletionFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
