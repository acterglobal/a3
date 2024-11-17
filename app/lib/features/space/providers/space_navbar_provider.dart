import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TabEntry {
  overview,
  news,
  pins,
  tasks,
  events,
  chats,
  spaces,
  members,
  actions;
}

final tabsProvider =
    FutureProvider.family<List<TabEntry>, String>((ref, spaceId) async {
  final space = await ref.watch(spaceProvider(spaceId).future);

  List<TabEntry> tabs = [];

  final spaceTopic = space.topic();
  if (spaceTopic != null) {
    tabs.add(TabEntry.overview);
  }

  if ((await space.isActerSpace()) == true) {
    final appSettings = await space.appSettings();

    if (appSettings.news().active()) {
      final newsList = await ref.watch(newsListProvider(spaceId).future);
      if (newsList.isNotEmpty) {
        tabs.add(TabEntry.news);
      }
    }

    if (appSettings.pins().active()) {
      final pinsList = await ref.watch(pinListProvider(spaceId).future);
      if (pinsList.isNotEmpty) {
        tabs.add(TabEntry.pins);
      }
    }

    if (appSettings.tasks().active()) {
      final taskList = await ref.watch(taskListsProvider(spaceId).future);
      if (taskList.isNotEmpty) {
        tabs.add(TabEntry.tasks);
      }
    }

    if (appSettings.events().active()) {
      final eventList = await ref.watch(allEventListProvider(spaceId).future);
      if (eventList.isNotEmpty) {
        tabs.add(TabEntry.events);
      }
    }
  }

  final hasChats = await ref.watch(hasSubChatsProvider(spaceId).future);
  if (hasChats) {
    tabs.add(TabEntry.chats);
  }

  final hasSpaces = await ref.watch(hasSubSpacesProvider(spaceId).future);
  if (hasSpaces) {
    tabs.add(TabEntry.spaces);
  }

  tabs.add(TabEntry.members);

  final membership = ref.watch(roomMembershipProvider(spaceId));
  bool canAddPin = membership.valueOrNull?.canString('CanPostPin') == true;
  bool canAddEvent = membership.valueOrNull?.canString('CanPostEvent') == true;
  bool canAddTask =
      membership.valueOrNull?.canString('CanPostTaskList') == true;
  bool canLinkSpaces =
      membership.valueOrNull?.canString('CanLinkSpaces') == true;

  //Show action menu only if you have at lease one permission
  if (canAddPin | canAddEvent | canAddTask | canLinkSpaces) {
    tabs.add(TabEntry.actions);
  }
  return tabs;
});
