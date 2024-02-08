import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/widgets/labs_notifications_settings_tile.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/settings/providers/notifications_mode_provider.dart';
import 'package:acter/features/settings/widgets/settings_section_with_title_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class _AddEmail extends StatefulWidget {
  final List<String> emails;
  const _AddEmail(
    this.emails,
  );

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
      title: const Text('Email address to add'),
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
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, emailAddr);
          },
          child: const Text('Add'),
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
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Notifications'),
        ),
        body: Column(
          children: [
            SettingsList(
              shrinkWrap: true,
              sections: [
                const SettingsSection(
                  title: Text('Notifications'),
                  tiles: [
                    LabsNotificationsSettingsTile(title: 'Push to this device'),
                  ],
                ),
                SettingsSection(
                  title: const Text('Default Modes'),
                  tiles: [
                    _notifSection(
                      context,
                      ref,
                      'Regular Space or Chat',
                      false,
                      false,
                    ),
                    _notifSection(
                      context,
                      ref,
                      'Encrypted Space or Chat',
                      true,
                      false,
                    ),
                    _notifSection(
                      context,
                      ref,
                      'One-on-one Space or Chat',
                      false,
                      true,
                    ),
                    _notifSection(
                      context,
                      ref,
                      'Encrypted One-on-one Space or Chat',
                      true,
                      true,
                    ),
                  ],
                ),
                _pushTargets(context, ref),
              ],
            ),
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
                NotificationConfiguration(isEncrypted, isOneToOne),
              ),
            )
            .valueOrNull ??
        '';
    return SettingsTile(
      title: Text(
        title,
      ),
      description: Text(
        notifToText(curNotifStatus) ?? '(unset)',
      ),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (String newMode) async {
          debugPrint('new value: $newMode');
          final client = ref.read(clientProvider);
          if (client == null) {
            // ignore: use_build_context_synchronously
            EasyLoading.showError('client not found');
            return;
          }
          EasyLoading.show();
          try {
            await client.setDefaultNotificationMode(
              isEncrypted,
              isOneToOne,
              newMode,
            );
            EasyLoading.showSuccess(
              'Notification status submitted',
            );
            ref.invalidate(
              currentNotificationModeProvider(
                NotificationConfiguration(isEncrypted, isOneToOne),
              ),
            );
          } catch (e) {
            EasyLoading.showError(
              'Notification status update failed: $e',
              duration: const Duration(seconds: 3),
            );
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'all',
            child: Text('All Messages'),
          ),
          const PopupMenuItem<String>(
            value: 'mentions',
            child: Text('Mentions and Keywords only'),
          ),
          const PopupMenuItem<String>(
            value: 'muted',
            child: Text('Muted'),
          ),
        ],
      ),
    );
  }

  SettingsSectionWithTitleActions _pushTargets(
    BuildContext context,
    WidgetRef ref,
  ) {
    final potentialEmails = ref.watch(possibleEmailToAddForPushProvider);
    return SettingsSectionWithTitleActions(
      title: const Text('Notification Targets'),
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
              onPressed: () async {
                final emailToAdd = await showDialog<String?>(
                  context: context,
                  builder: (BuildContext context) => _AddEmail(emails),
                );
                if (emailToAdd != null) {
                  EasyLoading.show(status: 'Adding $emailToAdd');
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
                    EasyLoading.showError(
                      'Failed to add $emailToAdd: $e',
                    );
                    return;
                  }
                  ref.invalidate(pushersProvider);
                  EasyLoading.showSuccess(
                    '$emailToAdd added to pusher list',
                  );
                }
              },
            ),
          ];
        },
      ),
      tiles: ref.watch(pushersProvider).when(
            data: (items) {
              if (items.isEmpty) {
                return [
                  SettingsTile(
                    title: const Text('no push targets added yet'),
                  ),
                ];
              }
              return items
                  .map(
                    (item) => _pusherTile(context, ref, item),
                  )
                  .toList();
            },
            error: (e, s) => [
              SettingsTile(
                title: Text('failed to load push targets: $e'),
              ),
            ],
            loading: () => [
              SettingsTile(
                title: const Text('loading targets'),
              ),
            ],
          ),
    );
  }

  SettingsTile _pusherTile(BuildContext context, WidgetRef ref, Pusher item) {
    final isEmail = item.isEmailPusher();
    return SettingsTile(
      leading: isEmail
          ? const Icon(Atlas.envelope)
          : const Icon(Atlas.mobile_portrait_thin),
      title: isEmail ? Text(item.pushkey()) : Text(item.deviceDisplayName()),
      description: isEmail ? null : Text(item.appDisplayName()),
      trailing: const Icon(Atlas.dots_vertical_thin),
      onPressed: (context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Push Target Details'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('AppId'),
                  subtitle: Text(item.appId()),
                ),
                ListTile(
                  title: const Text('PushKey'),
                  subtitle: Text(item.pushkey()),
                ),
                ListTile(
                  title: const Text('App Name'),
                  subtitle: Text(item.appDisplayName()),
                ),
                ListTile(
                  title: const Text('Device Name'),
                  subtitle: Text(item.deviceDisplayName()),
                ),
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(item.lang()),
                ),
              ],
            ),
            // alert dialog with details;
          ),
          actions: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context, null);
                  EasyLoading.show(status: 'Deleting push target');
                  try {
                    await item.delete();
                    EasyLoading.showSuccess('Push target deleted');
                    ref.invalidate(possibleEmailToAddForPushProvider);
                    ref.invalidate(pushersProvider);
                  } catch (e) {
                    EasyLoading.showSuccess(
                      'Deletion failed: $e',
                      duration: const Duration(seconds: 3),
                    );
                  }
                },
                child: const Text(
                  'Delete Target',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Close Dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
