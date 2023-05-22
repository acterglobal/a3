import 'package:acter/main/routing/routes.dart';
import 'package:acter/main/routing/routing.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

final settingsMenuProvider =
    Provider.autoDispose.family<Widget, BuildContext>((ref, context) {
  final currentRoute = ref.watch(currentRoutingLocation);
  bool isSelected(Routes route) => currentRoute == route.route;

  return SettingsList(
    sections: [
      SettingsSection(
        title: Text('Common'),
        tiles: <SettingsTile>[
          SettingsTile.navigation(
            leading: Icon(Icons.language),
            title: Text('Language'),
            value: Text('English'),
          ),
          SettingsTile.switchTile(
            onToggle: (value) {},
            initialValue: true,
            leading: Icon(Icons.format_paint),
            title: Text('Enable custom theme'),
          ),
        ],
      ),
      SettingsSection(
        title: Text('Extra'),
        tiles: <SettingsTile>[
          SettingsTile.navigation(
            leading: const Icon(Atlas.lab_appliance_thin),
            title: Text('Labs'),
          ),
          SettingsTile.navigation(
            leading: const Icon(Atlas.lab_appliance_thin),
            title: Text('Info'),
            // selected: isSelected(Routes.licenses),
            // onTap: () => context.pushNamed(Routes.licenses.name),
          ),
          SettingsTile.switchTile(
            onToggle: (value) {},
            initialValue: true,
            leading: Icon(Icons.format_paint),
            title: Text('Enable custom theme'),
          ),
        ],
      ),
    ],
  );
  //     ListTile(
  //       title: const Text('Labs'),
  //       leading: const Icon(Atlas.lab_appliance_thin),
  //       selected: isSelected(Routes.settingsLabs),
  //       onTap: () => context.pushNamed(Routes.settingsLabs.name),
  //     ),
  //     ListTile(
  //       title: const Text('Info'),
  //       leading: const Icon(Atlas.info_circle_thin),
  //       selected: isSelected(Routes.licenses),
  //       onTap: () => context.pushNamed(Routes.licenses.name),
  //     ),
  //   ],
  // ),
  // ];
});
