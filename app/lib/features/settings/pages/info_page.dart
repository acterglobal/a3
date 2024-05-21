import 'dart:convert';

import 'package:acter/common/toolkit/buttons/danger_action_button.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/bug_report/const.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

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
    final deviceId =
        ref.watch(alwaysClientProvider.select((a) => a.deviceId().toString()));
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${L10n.of(context).acterApp} ${L10n.of(context).info}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(
                L10n.of(context).appDefaults,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: Text(
                    L10n.of(context).homeServerName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultServerName),
                ),
                SettingsTile(
                  title: Text(
                    L10n.of(context).homeServerURL,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultServerUrl),
                ),
                SettingsTile(
                  title: Text(
                    L10n.of(context).sessionTokenName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(defaultSessionKey),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                L10n.of(context).debugInfo,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: Text(
                    L10n.of(context).version,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  value: const Text(versionName),
                ),
                isDevBuild
                    ? SettingsTile(
                        title: Text(
                          L10n.of(context).rageShakeAppName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: const Text(appName),
                      )
                    : SettingsTile(
                        title: Text(
                          L10n.of(context).rageShakeAppNameDigest,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: Text('${sha1.convert(utf8.encode(appName))}'),
                      ),
                isDevBuild
                    ? SettingsTile(
                        title: Text(
                          L10n.of(context).rageShakeTargetUrl,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: const Text(rageshakeUrl),
                      )
                    : SettingsTile(
                        title: Text(
                          L10n.of(context).rageShakeTargetUrlDigest,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value:
                            Text('${sha1.convert(utf8.encode(rageshakeUrl))}'),
                      ),
                isDevBuild
                    ? SettingsTile(
                        title: Text(
                          L10n.of(context).deviceId,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: Text(deviceId),
                      )
                    : SettingsTile(
                        title: Text(
                          L10n.of(context).deviceIdDigest,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        value: Text('${sha1.convert(utf8.encode(deviceId))}'),
                      ),
                SettingsTile(
                  title: Text(
                    L10n.of(context).httpProxy,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: _displayHttpProxyEditor,
                  value: Text(httpProxySetting),
                ),
                SettingsTile(
                  title: Text(
                    L10n.of(context).logSettings,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onPressed: _displayDebugLevelEditor,
                  value: Text(rustLogSetting),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                L10n.of(context).thirdParty,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              tiles: [
                SettingsTile.navigation(
                  title: Text(L10n.of(context).licenses),
                  value: Text(L10n.of(context).builtOnShouldersOfGiants),
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
      L10n.of(context).setDebugLevel,
      L10n.of(context).debugLevel,
    );
  }

  Future<void> _displayHttpProxyEditor(BuildContext context) async {
    await _displaySettingsEditor(
      context,
      proxyKey,
      httpProxySetting,
      L10n.of(context).setHttpProxy,
      L10n.of(context).httpProxy,
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
              Text(L10n.of(context).needsAppRestartToTakeEffect),
              TextField(
                controller: textFieldController,
                decoration: InputDecoration(hintText: fieldName),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            ActerDangerActionButton(
              onPressed: () async {
                await setSetting(logKey, null);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(L10n.of(context).reset),
            ),
            OutlinedButton(
              child: Text(L10n.of(context).cancel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ActerPrimaryActionButton(
              child: Text(L10n.of(context).save),
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
