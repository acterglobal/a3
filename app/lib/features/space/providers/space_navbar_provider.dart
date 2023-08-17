import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef MakeIconFn = Widget Function(BuildContext);

class TabEntry {
  final Key key;
  final String label;
  final String target;
  final MakeIconFn makeIcon;

  const TabEntry({
    required this.key,
    required this.makeIcon,
    required this.label,
    required this.target,
  });
}

final tabsProvider =
    FutureProvider.family<List<TabEntry>, String>((ref, spaceId) async {
  final features = ref.watch(featuresProvider);
  final space = await ref.watch(maybeSpaceProvider(spaceId).future);
  bool isActive(f) => features.isActive(f);
  List<TabEntry> tabs = [
    TabEntry(
      key: const Key('overview'),
      label: 'Overview',
      makeIcon: (ctx) => const Icon(Atlas.layout_half_thin),
      target: Routes.space.name,
    ),
  ];

  if (space != null && (await space.isActerSpace())) {
    if (isActive(LabsFeature.pins)) {
      tabs.add(
        TabEntry(
          key: const Key('pins'),
          label: 'Pins',
          makeIcon: (ctx) => const Icon(Atlas.pin_thin),
          target: Routes.spacePins.name,
        ),
      );
    }

    if (isActive(LabsFeature.tasks)) {
      tabs.add(
        TabEntry(
          key: const Key('tasks'),
          label: 'Tasks',
          makeIcon: (context) => SvgPicture.asset(
            'assets/images/tasks.svg',
            semanticsLabel: 'tasks',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
          target: Routes.space.name,
        ),
      );
    }

    if (isActive(LabsFeature.events)) {
      tabs.add(
        TabEntry(
          key: const Key('events'),
          label: 'Events',
          makeIcon: (ctx) => const Icon(Atlas.calendar_schedule_thin),
          target: Routes.spaceEvents.name,
        ),
      );
    }

    tabs.add(
      TabEntry(
        key: const Key('chat'),
        label: 'Chats',
        makeIcon: (ctx) => const Icon(Atlas.chats_thin),
        target: Routes.spaceChats.name,
      ),
    );
  }
  tabs.add(
    TabEntry(
      key: const Key('spaces'),
      label: 'Spaces',
      makeIcon: (ctx) => const Icon(Atlas.connection_thin),
      target: Routes.spaceRelatedSpaces.name,
    ),
  );

  tabs.add(
    TabEntry(
      key: const Key('members'),
      label: 'Members',
      makeIcon: (ctx) => const Icon(Atlas.group_team_collective_thin),
      target: Routes.spaceMembers.name,
    ),
  );
  return tabs;
});

class SelectedTabNotifier extends Notifier<Key> {
  @override
  Key build() {
    return const Key('overview');
  }

  void switchTo(Key input) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      state = input;
    });
  }
}

final selectedTabKeyProvider =
    NotifierProvider<SelectedTabNotifier, Key>(() => SelectedTabNotifier());

final selectedTabIdxProvider =
    FutureProvider.autoDispose.family<int, String>((ref, spaceId) async {
  final tabs = await ref.watch(tabsProvider(spaceId).future);
  final selectedKey = ref.watch(selectedTabKeyProvider);
  final index = tabs.indexWhere((e) => e.key == selectedKey);
  return index < 0 ? 0 : index;
});
