import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:acter/main/routing/routing.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:settings_ui/settings_ui.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    bool isSelected(Routes route) {
      debugPrint(
        '${route.route} $currentRoute, ${currentRoute == route.route}',
      );
      return currentRoute == route.route;
    }

    return SettingsList(
      sections: [
        SettingsSection(
          title: const Text('App'),
          tiles: [
            CustomSettingsTile(
              child: ListTile(
                title: const Text('Labs'),
                leading: const Icon(Atlas.lab_appliance_thin),
                selected: isSelected(Routes.settingsLabs),
                onTap: () => context.pushNamed(Routes.settingsLabs.name),
              ),
            ),
            CustomSettingsTile(
              child: ListTile(
                title: const Text('Info'),
                leading: const Icon(Atlas.info_circle_thin),
                selected: isSelected(Routes.info),
                onTap: () => context.pushNamed(Routes.info.name),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
