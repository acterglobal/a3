import 'package:acter/features/bug_report/const.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
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
  String httpProxySetting = defaultHttpProxy;

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Acter App Info',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(
                'App Defaults',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: Text(
                    'Homeserver Name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultServerName),
                ),
                SettingsTile(
                  title: Text(
                    'Homeserver URL',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultServerUrl),
                ),
                SettingsTile(
                  title: Text(
                    'Session Token Name',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultSessionKey),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                'Debug Info',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: Text(
                    'Version',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(versionName),
                ),
                isDevBuild
                    ? SettingsTile(
                        title: Text(
                          'Rageshake App Name',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: const Text(appName),
                      )
                    : SettingsTile(
                        title: Text(
                          'Rageshake App Name Digest',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: Text('${sha1.convert(utf8.encode(appName))}'),
                      ),
                isDevBuild
                    ? SettingsTile(
                        title: Text(
                          'Rageshake Target Url',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: const Text(rageshakeUrl),
                      )
                    : SettingsTile(
                        title: Text(
                          'Rageshake Target Url Digest',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value:
                            Text('${sha1.convert(utf8.encode(rageshakeUrl))}'),
                      ),
                SettingsTile(
                  title: Text(
                    'HTTP Proxy',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: _displayHttpProxyEditor,
                  value: Text(httpProxySetting),
                ),
                SettingsTile(
                  title: Text(
                    'Rust Log Settings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: _displayDebugLevelEditor,
                  value: Text(rustLogSetting),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                '3rd Party',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
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

  Future<void> fetchSettings() async {
    final preferences = await sharedPrefs();
    final rustLog = preferences.getString(rustLogKey) ?? defaultLogSetting;
    final httpProxy = preferences.getString(proxyKey) ?? defaultHttpProxy;
    if (mounted) {
      setState(() {
        rustLogSetting = rustLog;
        httpProxySetting = httpProxy;
      });
    }
  }

  Future<void> setSetting(String logKey, String? settings) async {
    final preferences = await sharedPrefs();
    if (settings == null || settings.isEmpty) {
      preferences.remove(logKey);
    } else {
      preferences.setString(logKey, settings);
    }
    await fetchSettings();
  }

  Future<void> _displayDebugLevelEditor(BuildContext context) async {
    await _displaySettingsEditor(
      context,
      rustLogKey,
      rustLogSetting,
      'Set Debug level',
      'Debug Level',
    );
  }

  Future<void> _displayHttpProxyEditor(BuildContext context) async {
    await _displaySettingsEditor(
      context,
      proxyKey,
      httpProxySetting,
      'Set HTTP Proxy',
      'HTTP Proxy',
    );
  }

  Future<void> _displaySettingsEditor(
    BuildContext context,
    String logKey,
    String currentValue,
    String title,
    String fieldName,
  ) async {
    TextEditingController textFieldController =
        TextEditingController(text: currentValue);
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Wrap(
            children: [
              const Text('needs an app restart to take effect'),
              TextField(
                controller: textFieldController,
                decoration: InputDecoration(hintText: fieldName),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.red),
              ),
              onPressed: () async {
                await setSetting(logKey, null);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Reset'),
            ),
            OutlinedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                await setSetting(logKey, textFieldController.text);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
