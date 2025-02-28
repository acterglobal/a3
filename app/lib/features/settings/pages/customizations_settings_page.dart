import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class _SystemLinksTile extends ConsumerWidget {
  const _SystemLinksTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openSysSettings = ref.watch(openSystemLinkSettingsProvider);
    final lang = L10n.of(context);
    return OptionsSettingsTile<OpenSystemLinkSetting>(
      selected: openSysSettings,
      title: lang.systemLinksTitle,
      explainer: lang.systemLinksExplainer,
      options: [
        (OpenSystemLinkSetting.open, lang.systemLinksOpen),
        (OpenSystemLinkSetting.copy, lang.systemLinksCopy),
      ],
      onSelect: (newVal) async {
        await ref.read(openSystemLinkSettingsProvider.notifier).set(newVal);
      },
    );
  }
}

class CustomizationsSettingsPage extends ConsumerWidget {
  const CustomizationsSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.customizationsTitle),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              tiles: [CustomSettingsTile(child: _SystemLinksTile())],
            ),
          ],
        ),
      ),
    );
  }
}
