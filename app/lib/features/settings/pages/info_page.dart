import 'dart:convert';

import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/config/setup.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
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
  String httpProxySetting = Env.defaultHttpProxy;

  @override
  void initState() {
    super.initState();
    fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final appNameDigest = sha1.convert(utf8.encode(Env.rageshakeAppName));
    final urlDigest = sha1.convert(utf8.encode(Env.rageshakeUrl));
    final deviceId = ref.watch(deviceIdProvider).valueOrNull;
    final devIdDigest =
        deviceId != null ? sha1.convert(utf8.encode(deviceId)) : 'none';
    final allowReportSending =
        ref.watch(allowSentryReportingProvider).valueOrNull ?? isNightly;
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(
            '${lang.acterApp} ${lang.info}',
            style: textTheme.titleLarge,
          ),
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(
                lang.appDefaults,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              tiles: <SettingsTile>[
                SettingsTile(
                  title: Text(lang.homeServerName, style: textTheme.bodyMedium),
                  value: const Text(Env.defaultHomeserverName),
                ),
                SettingsTile(
                  title: Text(lang.homeServerURL, style: textTheme.bodyMedium),
                  value: const Text(Env.defaultHomeserverUrl),
                ),
                SettingsTile(
                  title: Text(
                    lang.sessionTokenName,
                    style: textTheme.bodyMedium,
                  ),
                  value: const Text(Env.defaultActerSession),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                lang.debugInfo,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              tiles: <SettingsTile>[
                SettingsTile.switchTile(
                  initialValue: allowReportSending,
                  onToggle: (newVal) {
                    setCanReportToSentry(newVal);
                    ref.invalidate(allowSentryReportingProvider);
                  },
                  title: Text(lang.sendCrashReportsTitle),
                  description: Text(lang.sendCrashReportsInfo),
                ),
                SettingsTile(
                  title: Text(lang.version, style: textTheme.bodyMedium),
                  value: const Text(Env.rageshakeAppVersion),
                ),
                isDevBuild
                    ? SettingsTile(
                      title: Text(
                        lang.rageShakeAppName,
                        style: textTheme.bodyMedium,
                      ),
                      value: const Text(Env.rageshakeAppName),
                    )
                    : SettingsTile(
                      title: Text(
                        lang.rageShakeAppNameDigest,
                        style: textTheme.bodyMedium,
                      ),
                      value: Text(appNameDigest.toString()),
                    ),
                isDevBuild
                    ? SettingsTile(
                      title: Text(
                        lang.rageShakeTargetUrl,
                        style: textTheme.bodyMedium,
                      ),
                      value: const Text(Env.rageshakeUrl),
                    )
                    : SettingsTile(
                      title: Text(
                        lang.rageShakeTargetUrlDigest,
                        style: textTheme.bodyMedium,
                      ),
                      value: Text(urlDigest.toString()),
                    ),
                isDevBuild
                    ? SettingsTile(
                      title: Text(lang.deviceId, style: textTheme.bodyMedium),
                      value: Text(deviceId ?? 'none'),
                    )
                    : SettingsTile(
                      title: Text(
                        lang.deviceIdDigest,
                        style: textTheme.bodyMedium,
                      ),
                      value: Text(devIdDigest.toString()),
                    ),
                SettingsTile(
                  title: Text(lang.httpProxy, style: textTheme.bodyMedium),
                  onPressed: _displayHttpProxyEditor,
                  value: Text(httpProxySetting),
                ),
                SettingsTile(
                  title: Text(lang.logSettings, style: textTheme.bodyMedium),
                  onPressed: _displayDebugLevelEditor,
                  value: Text(rustLogSetting),
                ),
              ],
            ),
            SettingsSection(
              title: Text(
                lang.thirdParty,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              tiles: [
                SettingsTile.navigation(
                  title: Text(lang.licenses),
                  value: Text(lang.builtOnShouldersOfGiants),
                  leading: const Icon(Atlas.list_file_thin),
                  onPressed: (context) {
                    context.pushNamed(Routes.licenses.name);
                  },
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
    final httpProxy = preferences.getString(proxyKey) ?? Env.defaultHttpProxy;
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
    final lang = L10n.of(context);
    await _displaySettingsEditor(
      context,
      rustLogKey,
      rustLogSetting,
      lang.setDebugLevel,
      lang.debugLevel,
    );
  }

  Future<void> _displayHttpProxyEditor(BuildContext context) async {
    final lang = L10n.of(context);
    await _displaySettingsEditor(
      context,
      proxyKey,
      httpProxySetting,
      lang.setHttpProxy,
      lang.httpProxy,
    );
  }

  Future<void> _displaySettingsEditor(
    BuildContext context,
    String logKey,
    String currentValue,
    String title,
    String fieldName,
  ) async {
    TextEditingController textFieldController = TextEditingController(
      text: currentValue,
    );
    return showDialog(
      context: context,
      builder: (context) {
        final lang = L10n.of(context);
        return AlertDialog(
          title: Text(title),
          content: Wrap(
            children: [
              Text(lang.needsAppRestartToTakeEffect),
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
              child: Text(lang.reset),
            ),
            OutlinedButton(
              child: Text(lang.cancel),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ActerPrimaryActionButton(
              child: Text(lang.save),
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
