import 'package:acter/features/bug_report/providers/notifiers/bug_report_notifier.dart';
import 'package:acter/features/settings/widgets/in_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class SettingsInfoPage extends ConsumerStatefulWidget {
  const SettingsInfoPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SettingsInfoPageState();
}

class _SettingsInfoPageState extends ConsumerState<SettingsInfoPage> {
  String rustLogSetting = defaultLogSetting;

  @override
  void initState() {
    super.initState();
    fetchRustLogSettings();
  }

  @override
  Widget build(BuildContext context) {
    return InSettings(
      child: Scaffold(
        appBar: AppBar(title: const Text('App Info')),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: const Text('App Defaults'),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: const Text('Homeserver Name'),
                  value: const Text(defaultServerName),
                ),
                SettingsTile(
                  title: const Text('Homeserver URL'),
                  value: const Text(defaultServerUrl),
                ),
                SettingsTile(
                  title: const Text('Session Token Name'),
                  value: const Text(defaultSessionKey),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('Debug Info'),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: const Text('Version'),
                  value: const Text(versionName),
                ),
                isDevBuild
                    ? SettingsTile(
                        title: const Text('Rageshake App Name'),
                        value: const Text(appName),
                      )
                    : SettingsTile(
                        title: const Text('Rageshake App Name Digest'),
                        value: Text('${sha1.convert(utf8.encode(appName))}'),
                      ),
                isDevBuild
                    ? SettingsTile(
                        title: const Text('Rageshake Target Url'),
                        value: const Text(rageshakeUrl),
                      )
                    : SettingsTile(
                        title: const Text('Rageshake Target Url Digest'),
                        value:
                            Text('${sha1.convert(utf8.encode(rageshakeUrl))}'),
                      ),
                SettingsTile(
                  title: const Text('Rust Log Settings'),
                  onPressed: _displayDebugLevelEditor,
                  value: Text(rustLogSetting),
                ),
              ],
            ),
            SettingsSection(
              title: const Text('3rd Party'),
              tiles: [
                SettingsTile.navigation(
                  title: const Text('Licenses'),
                  value: const Text('Built on the shoulders of giants'),
                  leading: const Icon(Atlas.list_file_thin),
                  onPressed: (context) => context.pushNamed(
                    Routes.licenses.name,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchRustLogSettings() async {
    final preferences = await sharedPrefs();
    final rustLog = preferences.getString(rustLogKey) ?? defaultLogSetting;
    setState(() {
      rustLogSetting = rustLog;
    });
  }

  Future<void> setRustLogSettings(String? settings) async {
    final preferences = await sharedPrefs();
    if (settings == null || settings.isEmpty) {
      preferences.remove(rustLogKey);
    } else {
      preferences.setString(rustLogKey, settings);
    }
    await fetchRustLogSettings();
  }

  Future<void> _displayDebugLevelEditor(BuildContext context) async {
    TextEditingController textFieldController =
        TextEditingController(text: rustLogSetting);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Debug level'),
          content: Wrap(
            children: [
              const Text('needs an app restart to take effect'),
              TextField(
                controller: textFieldController,
                decoration: const InputDecoration(hintText: 'Debug Level'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Reset to default'),
              onPressed: () async {
                await setRustLogSettings('');
                if (context.mounted) Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                await setRustLogSettings(textFieldController.text);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
