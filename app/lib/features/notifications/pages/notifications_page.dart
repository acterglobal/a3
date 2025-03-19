import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/config/notifications/init.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/notifications/actions/update_autosubscribe.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/features/notifications/widgets/labs_notifications_settings_tile.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/notifications_mode_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/app_notifications_settings_tile.dart';
import 'package:acter/features/settings/widgets/settings_section_with_title_actions.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_notifify/util.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::settings::notifications');

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
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.emailAddressToAdd),
      content: DropdownMenu<String>(
        initialSelection: widget.emails.first,
        onSelected: (String? value) {
          // This is called when the user selects an item.
          setState(() {
            emailAddr = value.expect('email selection is invalid');
          });
        },
        dropdownMenuEntries:
            widget.emails.map((String value) {
              return DropdownMenuEntry<String>(value: value, label: value);
            }).toList(),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(lang.cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => Navigator.pop(context, emailAddr),
          child: Text(lang.add),
        ),
      ],
    );
  }
}

class NotificationsSettingsPage extends ConsumerWidget {
  const NotificationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(lang.notifications),
        ),
        body: SettingsList(
          shrinkWrap: true,
          sections: [
            SettingsSection(
              title: Text(lang.notifications),
              tiles: [
                LabsNotificationsSettingsTile(title: lang.pushToThisDevice),
                AppsNotificationsSettingsTile(
                  title: lang.boosts,
                  description: lang.notifyAboutSpaceUpdates,
                  appKey: 'global.acter.dev.news',
                ),
                SettingsTile.switchTile(
                  title: Text(lang.autoSubscribeSettingsTitle),
                  description: Text(lang.autoSubscribeFeatureDesc),
                  initialValue: ref.watch(autoSubscribeProvider).value == true,
                  onToggle: (newVal) async {
                    await updateAutoSubscribe(ref, lang, newVal);
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(lang.defaultModes),
              tiles: [
                _notifSection(
                  context,
                  ref,
                  lang.regularSpaceOrChat,
                  false,
                  false,
                ),
                _notifSection(
                  context,
                  ref,
                  lang.encryptedSpaceOrChat,
                  true,
                  false,
                ),
                _notifSection(context, ref, lang.dmChat, false, true),
                _notifSection(context, ref, lang.encryptedDMChat, true, true),
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
    final lang = L10n.of(context);
    final curNotifStatus =
        ref
            .watch(
              currentNotificationModeProvider((
                encrypted: isEncrypted,
                oneToOne: isOneToOne,
              )),
            )
            .valueOrNull ??
        '';
    return SettingsTile(
      title: Text(title),
      description: Text(
        notifToText(context, curNotifStatus) ?? '(${lang.unset})',
      ),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected:
            (newMode) => _onNotifSectionChange(
              context,
              ref,
              isEncrypted,
              isOneToOne,
              newMode,
            ),
        itemBuilder:
            (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'all',
                child: Text(lang.allMessages),
              ),
              PopupMenuItem<String>(
                value: 'mentions',
                child: Text(lang.mentionsAndKeywordsOnly),
              ),
              PopupMenuItem<String>(value: 'muted', child: Text(lang.muted)),
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
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.changingNotificationMode);
    try {
      final settings = await ref.read(notificationSettingsProvider.future);
      await settings.setDefaultNotificationMode(
        isEncrypted,
        isOneToOne,
        newMode,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.notificationStatusSubmitted);
    } catch (e, s) {
      _log.severe('Failed to update notification status', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.notificationStatusUpdateFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  SettingsSectionWithTitleActions _pushTargets(
    BuildContext context,
    WidgetRef ref,
  ) {
    final lang = L10n.of(context);
    final emailsLoader = ref.watch(possibleEmailToAddForPushProvider);
    final pushersLoader = ref.watch(pushersProvider);
    return SettingsSectionWithTitleActions(
      title: Text(lang.notificationTargets),
      actions: [
        IconButton(
          onPressed: () {
            ref.invalidate(pushersProvider);
            EasyLoading.showToast(lang.refreshing);
          },
          icon: const Icon(Atlas.refresh_account_arrows_thin),
        ),
        emailsLoader.maybeWhen(
          orElse: () => const SizedBox.shrink(),
          data:
              (emails) =>
                  emails.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                        icon: const Icon(Atlas.plus_circle_thin),
                        iconSize: 20,
                        color: Theme.of(context).colorScheme.surface,
                        onPressed: () => _onTargetAdd(context, ref, emails),
                      ),
        ),
      ],
      tiles: pushersLoader.when(
        data: (pushers) {
          if (pushers.isEmpty) {
            return [SettingsTile(title: Text(lang.noPushTargetsAddedYet))];
          }
          return pushers
              .map((pusher) => _pusherTile(context, ref, pusher))
              .toList();
        },
        error: (e, s) {
          _log.severe('Failed to load pushers', e, s);
          return [SettingsTile(title: Text(lang.failedToLoadPushTargets(e)))];
        },
        loading: () => [SettingsTile(title: Text(lang.loadingTargets))],
      ),
    );
  }

  Future<void> _onTargetAdd(
    BuildContext context,
    WidgetRef ref,
    List<String> emails,
  ) async {
    final lang = L10n.of(context);
    final emailToAdd = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) => _AddEmail(emails),
    );
    if (!context.mounted) return;
    if (emailToAdd == null) return;
    EasyLoading.show(status: lang.adding(emailToAdd));
    final client = await ref.read(alwaysClientProvider.future);
    try {
      await client.addEmailPusher(
        appIdPrefix,
        await deviceName(),
        emailToAdd,
        null,
      );
      ref.invalidate(possibleEmailToAddForPushProvider);
    } catch (e, s) {
      _log.severe('Failed to add email pusher', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToAdd(emailToAdd, e),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    ref.invalidate(pushersProvider);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.addedToPusherList(emailToAdd));
  }

  SettingsTile _pusherTile(BuildContext context, WidgetRef ref, Pusher item) {
    final lang = L10n.of(context);
    final isEmail = item.isEmailPusher();
    return SettingsTile(
      leading: Icon(isEmail ? Atlas.envelope : Atlas.mobile_portrait_thin),
      title: Text(isEmail ? item.pushkey() : item.deviceDisplayName()),
      description: isEmail ? null : Text(item.appDisplayName()),
      trailing: const Icon(Atlas.dots_vertical_thin),
      onPressed:
          (context) => showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(lang.pushTargetDetails),
                  content: SizedBox(
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          title: Text(lang.appId),
                          subtitle: Text(item.appId()),
                        ),
                        ListTile(
                          title: Text(lang.pushKey),
                          subtitle: Text(item.pushkey()),
                        ),
                        ListTile(
                          title: Text(lang.appName),
                          subtitle: Text(item.appDisplayName()),
                        ),
                        ListTile(
                          title: Text(lang.deviceName),
                          subtitle: Text(item.deviceDisplayName()),
                        ),
                        ListTile(
                          title: Text(lang.language),
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
                      child: Text(lang.closeDialog),
                    ),
                    ActerDangerActionButton(
                      onPressed: () => _onTargetDelete(context, ref, item),
                      child: Text(lang.deleteTarget),
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
    final lang = L10n.of(context);
    Navigator.pop(context, null);
    EasyLoading.show(status: lang.deletingPushTarget);
    try {
      await item.delete();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.pushTargetDeleted);
      ref.invalidate(possibleEmailToAddForPushProvider);
      ref.invalidate(pushersProvider);
    } catch (e, s) {
      _log.severe('Failed to delete email pusher', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.deletionFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
