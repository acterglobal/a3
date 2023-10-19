import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/features/settings/widgets/settings_section_with_title_actions.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

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
                validator: (value) => value != null &&
                        value.startsWith('@') &&
                        value.contains(':')
                    ? null
                    : 'Format must be @user:server.tld',
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
                _pushTargets(context, ref),
              ],
            ),
          ],
        ),
      ),
    );
  }

  SettingsSectionWithTitleActions _pushTargets(
    BuildContext context,
    WidgetRef ref,
  ) {
    return SettingsSectionWithTitleActions(
      title: const Text('Notification Targets'),
      actions: [
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
              builder: (BuildContext context) => const AddEmail(),
            );
            if (emailToAdd != null) {
              final client = ref.read(
                  clientProvider,); // is guaranteed because of the ignoredUsersProvider using it

              // await client.addEmailPusher(emailToAdd);
              if (context.mounted) {
                customMsgSnackbar(
                  context,
                  '$emailToAdd added to block list. UI might take a bit too update',
                );
              }
            }
          },
        ),
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
      title: Text(item.deviceDisplayName()),
      description: Text(item.appDisplayName()),
    );
  }
}
