import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef MakeIconFn = Widget Function(BuildContext, Color color);

class TabEntry {
  static const overview = Key('overview');
  static const pins = Key('pins');
  static const tasks = Key('tasks');
  static const events = Key('events');
  static const chatsKey = Key('chat');
  static const spacesKey = Key('spaces');
  static const membersKey = Key('members');

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
  final space = await ref.read(spaceProvider(spaceId).future);
  final spaceTopic = space.topic();
  final pinsList = await ref.read(spacePinsProvider(space).future);
  final taskList = await ref.read(spaceTasksListsProvider(spaceId).future);
  final eventList = await ref.read(spaceEventsProvider(spaceId).future);
  final chatsList = await ref.read(relatedChatsProvider(spaceId).future);
  final spacesList = await ref.read(relatedSpacesProvider(spaceId).future);

  List<TabEntry> tabs = [];

  if (spaceTopic != null) {
    tabs.add(
      TabEntry(
        key: TabEntry.overview,
        label: 'Overview',
        makeIcon: (ctx, color) => Icon(
          Atlas.layout_half_thin,
          color: color,
        ),
        target: Routes.space,
      ),
    );
  }

  if ((await space.isActerSpace()) == true) {
    final appSettings = await space.appSettings();
    if (appSettings.pins().active() && pinsList.isNotEmpty) {
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

    if (appSettings.tasks().active() && taskList.isNotEmpty) {
      tabs.add(
        TabEntry(
          key: TabEntry.tasks,
          label: 'Tasks',
          makeIcon: (ctx, color) => Icon(
            Atlas.list,
            color: color,
          ),
          target: Routes.spaceTasks,
        ),
      );
    }

    if (appSettings.events().active() && eventList.isNotEmpty) {
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

  if (chatsList.isNotEmpty) {
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
  }

  if (spacesList.isNotEmpty) {
    tabs.add(
      TabEntry(
        key: TabEntry.spacesKey,
        label: 'Spaces',
        makeIcon: (ctx, color) => Icon(
          Atlas.connection_thin,
          color: color,
        ),
        target: Routes.spaceRelatedSpaces,
      ),
    );
  }

  tabs.add(
    TabEntry(
      key: TabEntry.membersKey,
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
