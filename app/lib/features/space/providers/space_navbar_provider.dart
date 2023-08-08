import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TabEntry {
  final Key key;
  final String label;
  final String target;
  final Widget icon;

  const TabEntry({
    required this.key,
    required this.icon,
    required this.label,
    required this.target,
  });
}

final tabsProvider =
    Provider.family<List<TabEntry>, BuildContext>((ref, context) {
  final features = ref.watch(featuresProvider);
  bool isActive(f) => features.isActive(f);
  List<TabEntry> tabs = [
    TabEntry(
      key: const Key('overview'),
      label: 'Overview',
      icon: const Icon(Atlas.layout_half_thin),
      target: Routes.space.name,
    ),
  ];

  if (isActive(LabsFeature.pins)) {
    tabs.add(
      TabEntry(
        key: const Key('pins'),
        label: 'Pins',
        icon: const Icon(Atlas.pin_thin),
        target: Routes.spacePins.name,
      ),
    );
  }

  if (isActive(LabsFeature.tasks)) {
    tabs.add(
      TabEntry(
        key: const Key('tasks'),
        label: 'Tasks',
        icon: SvgPicture.asset(
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
        icon: const Icon(Atlas.calendar_schedule_thin),
        target: Routes.spaceEvents.name,
      ),
    );
  }

  tabs.add(
    TabEntry(
      key: const Key('chat'),
      label: 'Chats',
      icon: const Icon(Atlas.chats_thin),
      target: Routes.spaceChats.name,
    ),
  );
  tabs.add(
    TabEntry(
      key: const Key('spaces'),
      label: 'Spaces',
      icon: const Icon(Atlas.connection_thin),
      target: Routes.spaceRelatedSpaces.name,
    ),
  );

  tabs.add(
    TabEntry(
      key: const Key('members'),
      label: 'Members',
      icon: const Icon(Atlas.group_team_collective_thin),
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
    Future(() => state = input);
  }
}

final selectedTabKeyProvider =
    NotifierProvider<SelectedTabNotifier, Key>(() => SelectedTabNotifier());

final selectedTabIdxProvider =
    StateProvider.autoDispose.family<int, BuildContext>((ref, context) {
  final tabs = ref.watch(tabsProvider(context));
  final selectedKey = ref.watch(selectedTabKeyProvider);
  final index = tabs.indexWhere((e) => e.key == selectedKey);
  return index < 0 ? 0 : index;
});
