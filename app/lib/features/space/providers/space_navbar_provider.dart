import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

typedef MakeIconFn = Widget Function(BuildContext, Color color);

class TabEntry {
  static const chatsKey = Key('chat');
  static const overview = Key('overview');
  static const pins = Key('pins');
  static const tasks = Key('tasks');
  static const events = Key('events');

  final Key key;
  final String label;
  final Routes target;
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
      key: TabEntry.overview,
      label: 'Overview',
      makeIcon: (ctx, color) => Icon(
        Atlas.layout_half_thin,
        color: color,
      ),
      target: Routes.space,
    ),
  ];

  if ((await space?.isActerSpace()) == true) {
    final appSettings = await space!.appSettings();
    if (appSettings.pins().active()) {
      tabs.add(
        TabEntry(
          key: TabEntry.pins,
          label: 'Pins',
          makeIcon: (ctx, color) => Icon(
            Atlas.pin_thin,
            color: color,
          ),
          target: Routes.spacePins,
        ),
      );
    }

    if (isActive(LabsFeature.tasks) && appSettings.tasks().active()) {
      tabs.add(
        TabEntry(
          key: TabEntry.tasks,
          label: 'Tasks',
          makeIcon: (context, color) => SvgPicture.asset(
            'assets/images/tasks.svg',
            semanticsLabel: 'tasks',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              color,
              BlendMode.srcIn,
            ),
          ),
          target: Routes.spaceTasks,
        ),
      );
    }

    if (appSettings.events().active()) {
      tabs.add(
        TabEntry(
          key: TabEntry.events,
          label: 'Events',
          makeIcon: (ctx, color) => Icon(
            Atlas.calendar_schedule_thin,
            color: color,
          ),
          target: Routes.spaceEvents,
        ),
      );
    }
  }

  tabs.add(
    TabEntry(
      key: TabEntry.chatsKey,
      label: 'Chats',
      makeIcon: (ctx, color) => Icon(
        Atlas.chats_thin,
        color: color,
      ),
      target: Routes.spaceChats,
    ),
  );

  tabs.add(
    TabEntry(
      key: const Key('spaces'),
      label: 'Spaces',
      makeIcon: (ctx, color) => Icon(
        Atlas.connection_thin,
        color: color,
      ),
      target: Routes.spaceRelatedSpaces,
    ),
  );

  tabs.add(
    TabEntry(
      key: const Key('members'),
      label: 'Members',
      makeIcon: (ctx, color) => Icon(
        Atlas.group_team_collective_thin,
        color: color,
      ),
      target: Routes.spaceMembers,
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
