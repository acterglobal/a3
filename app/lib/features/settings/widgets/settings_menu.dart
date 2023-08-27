import 'package:acter/common/utils/utils.dart';
import 'package:acter/router/providers/router_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

const defaultSettingsMenuKey = Key('settings-menu');

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key = defaultSettingsMenuKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRoutingLocation);
    final size = MediaQuery.of(context).size;
    bool isSelected(Routes route) {
      debugPrint(
        '${route.route} $currentRoute, ${currentRoute == route.route}',
      );
      return currentRoute == route.route;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: const Text('Labs'),
            subtitle: const Text('Experimental Acter features'),
            leading: const Icon(Atlas.lab_appliance_thin),
            selected: isSelected(Routes.settingsLabs),
            onTap: () {
              isDesktop(context) || size.width > 770
                  ? context.goNamed(Routes.settingsLabs.name)
                  : context.pushNamed(Routes.settingsLabs.name);
            },
          ),
          ListTile(
            title: const Text('Info'),
            leading: const Icon(Atlas.info_circle_thin),
            selected: isSelected(Routes.info),
            onTap: () {
              isDesktop(context) || size.width > 770
                  ? context.goNamed(Routes.info.name)
                  : context.pushNamed(Routes.info.name);
            },
          ),
        ],
      ),
    );
  }
}
