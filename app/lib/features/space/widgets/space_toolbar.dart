import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceToolbar extends ConsumerWidget {
  static const optionsMenu = Key('space-options-menu');
  static const settingsMenu = Key('space-options-settings');
  final String spaceId;

  const SpaceToolbar({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final List<PopupMenuEntry> submenu = [];
    if (membership != null) {
      if (membership.canString('CanSetName')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.editSpace.name,
              pathParameters: {'spaceId': spaceId},
              queryParameters: {'spaceId': spaceId},
            ),
            child: const Text('Edit Details'),
          ),
        );
      }
    }

    submenu.addAll([
      PopupMenuItem(
        key: settingsMenu,
        onTap: () => context.pushNamed(
          Routes.spaceSettings.name,
          pathParameters: {'spaceId': spaceId},
        ),
        child: const Text('Settings'),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        onTap: () => _handleLeaveSpace(context, ref),
        child: const Text('Leave Space'),
      ),
    ]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop()
                ? context.pop()
                : context.goNamed(Routes.dashboard.name),
            child: Icon(
              Atlas.arrow_left,
              color: Theme.of(context).colorScheme.neutral5,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: PopupMenuButton(
              icon: Icon(
                key: optionsMenu,
                Icons.more_vert,
                color: Theme.of(context).colorScheme.neutral5,
              ),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              itemBuilder: (BuildContext context) => submenu,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLeaveSpace(
    BuildContext context,
    WidgetRef ref,
  ) {
    showAdaptiveDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => DefaultDialog(
        title: Column(
          children: <Widget>[
            const Icon(Icons.person_remove_outlined),
            const SizedBox(height: 5),
            Text('Leave Space', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        subtitle: const Text(
          'Are you sure you want to leave this space?',
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('No, I stay'),
          ),
          ElevatedButton(
            onPressed: () async {
              final space = await ref.read(spaceProvider(spaceId).future);
              await space.leave();
              // refresh spaces list
              ref.invalidate(spacesProvider);
              if (!context.mounted) {
                return;
              }
              context.pop();
              context.goNamed(Routes.dashboard.name);
            },
            child: const Text('Yes, Leave'),
          ),
        ],
      ),
    );
  }
}
