import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TabEntry {
  overview,
  updates,
  pins,
  tasks,
  events,
  suggestedChats,
  suggestedSpaces,
  chats,
  spaces,
  members,
  actions,
}

final tabsProvider = FutureProvider.family<List<TabEntry>, String>((
  ref,
  spaceId,
) async {
  final space = await ref.watch(spaceProvider(spaceId).future);

  List<TabEntry> tabs = [];

  final spaceTopic = space.topic();
  if (spaceTopic != null) {
    tabs.add(TabEntry.overview);
  }

  if ((await space.isActerSpace()) == true) {
    final appSettings = await space.appSettings();

    if (appSettings.news().active() || appSettings.stories().active()) {
      final updateList = await ref.watch(updateListProvider(spaceId).future);
      if (updateList.isNotEmpty) {
        tabs.add(TabEntry.updates);
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

  final suggestedChats = await ref.watch(
    suggestedChatsProvider(spaceId).future,
  );
  final hasSuggestedChats =
      suggestedChats.$1.isNotEmpty || suggestedChats.$2.isNotEmpty;
  if (hasSuggestedChats) {
    tabs.add(TabEntry.suggestedChats);
  }
  final suggestedSpaces = await ref.watch(
    suggestedSpacesProvider(spaceId).future,
  );
  final hasSuggestedSpaces =
      suggestedSpaces.$1.isNotEmpty || suggestedSpaces.$2.isNotEmpty;
  if (hasSuggestedSpaces) {
    tabs.add(TabEntry.suggestedSpaces);
  }

  final otherChats = await ref.watch(otherChatsProvider(spaceId).future);
  final hasChats = otherChats.$1.isNotEmpty || otherChats.$2.isNotEmpty;
  if (hasChats) {
    tabs.add(TabEntry.chats);
  }

  final otherSubSpaces = await ref.watch(
    otherSubSpacesProvider(spaceId).future,
  );
  final hasOtherSubSpaces =
      otherSubSpaces.$1.isNotEmpty || otherSubSpaces.$2.isNotEmpty;
  if (hasOtherSubSpaces) {
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
