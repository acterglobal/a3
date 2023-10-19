import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/room/widgets/notifications_settings_tile.dart';
import 'package:acter/features/settings/providers/notifications_mode_provider.dart';
import 'package:acter/features/settings/widgets/settings_section_with_title_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:email_validator/email_validator.dart';

class AddEmail extends StatefulWidget {
  const AddEmail({
    Key? key,
  }) : super(key: key);

  @override
  State<AddEmail> createState() => _AddEmailState();
}

class _AddEmailState extends State<AddEmail> {
  final TextEditingController emailAddr = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Email address to add'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: emailAddr,
                validator: (value) =>
                    value == null || !EmailValidator.validate(value)
                        ? 'Format must an Email'
                        : null,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, emailAddr.text);
            }
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
                SettingsSection(
                  title: const Text('Notifications'),
                  tiles: [
                    SettingsTile.switchTile(
                      title: const Text('Push to this device'),
                      description: Text(
                        !supportedPlatforms
                            ? 'Only supported on mobile (iOS & Android) right now'
                            : 'Needs App restart to activate',
                      ),
                      initialValue: supportedPlatforms &&
                          ref.watch(
                            isActiveProvider(LabsFeature.showNotifications),
                          ),
                      enabled: supportedPlatforms,
                      onToggle: (newVal) {
                        updateFeatureState(
                          ref,
                          LabsFeature.showNotifications,
                          newVal,
                        );
                        if (newVal) {
                          customMsgSnackbar(
                            context,
                            'Push enabled. Please restart to activate',
                          );
                        }
                      },
                    ),
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
    return SettingsSectionWithTitleActions(
      title: const Text('Notification Targets'),
      actions: const [
        // FIXME: enable once we have 3pid support
        // IconButton(
        //   icon: Icon(
        //     Atlas.plus_circle_thin,
        //     color: Theme.of(context).colorScheme.neutral5,
        //   ),
        //   iconSize: 20,
        //   color: Theme.of(context).colorScheme.surface,
        //   onPressed: () async {
        //     final emailToAdd = await showDialog<String?>(
        //       context: context,
        //       builder: (BuildContext context) => const AddEmail(),
        //     );
        //     if (emailToAdd != null) {
        //       EasyLoading.show();
        //       final client = ref.read(
        //         clientProvider,
        //       ); // is guaranteed because of the ignoredUsersProvider using it
        //       try {
        //         await client!.addEmailPusher(
        //           appIdPrefix,
        //           (await deviceName()),
        //           emailToAdd,
        //           null,
        //         );
        //       } catch (e) {
        //         EasyLoading.dismiss();
        //         // ignore: use_build_context_synchronously
        //         customMsgSnackbar(
        //           context,
        //           'Failed to add $emailToAdd: $e',
        //         );
        //         return;
        //       }
        //       EasyLoading.dismiss();
        //       if (context.mounted) {
        //         customMsgSnackbar(
        //           context,
        //           '$emailToAdd added to pusher list. UI might take a bit too update',
        //         );
        //         ref.invalidate(pushersProvider);
        //       }
        //     }
        //   },
        // ),
      ],
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
    return SettingsTile(
      leading: item.isEmailPusher()
          ? const Icon(Atlas.email_thin)
          : const Icon(Atlas.mobile_portrait_thin),
      title: Text(item.deviceDisplayName()),
      description: Text(item.appDisplayName()),
      trailing: const Icon(Atlas.dots_vertical_thin),
      onPressed: (context) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Target Details'),
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
                  EasyLoading.show();
                  await item.delete();
                  EasyLoading.dismiss();
                  ref.invalidate(pushersProvider);
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
