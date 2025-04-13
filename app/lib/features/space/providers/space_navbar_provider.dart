import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
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
  spacesLoadingError,
  members,
  actions,
}

class TabsNotifier extends FamilyNotifier<List<TabEntry>, String> {
  @override
  List<TabEntry> build(String spaceId) => [
    if (ref.watch(topicProvider(spaceId)).valueOrNull != null)
      TabEntry.overview,
    if (ref.watch(isActerSpace(spaceId)).valueOrNull == true)
      ..._getFeatures(spaceId),
    ..._childSpaces(spaceId),
    TabEntry.members,
    ..._getActions(spaceId),
  ];

  List<TabEntry> _getFeatures(String spaceId) {
    final appSettings =
        ref.watch(acterAppSettingsProvider(spaceId)).valueOrNull;
    if (appSettings == null) {
      return [];
    }

    final tabs = <TabEntry>[];

    if (appSettings.news().active() || appSettings.stories().active()) {
      if (ref.watch(updateListProvider(spaceId)).valueOrNull?.isNotEmpty ==
          true) {
        tabs.add(TabEntry.updates);
      }
    }

    if (appSettings.pins().active()) {
      if (ref.watch(pinListProvider(spaceId)).valueOrNull?.isNotEmpty == true) {
        tabs.add(TabEntry.pins);
      }
    }

    if (appSettings.tasks().active()) {
      if (ref.watch(taskListsProvider(spaceId)).valueOrNull?.isNotEmpty ==
          true) {
        tabs.add(TabEntry.tasks);
      }
    }

    if (appSettings.events().active()) {
      if (ref.watch(allEventListProvider(spaceId)).valueOrNull?.isNotEmpty ==
          true) {
        tabs.add(TabEntry.events);
      }
    }
    return tabs;
  }

  List<TabEntry> _childSpaces(String spaceId) {
    final tabs = <TabEntry>[];

    final suggestedChats =
        ref.watch(suggestedChatsProvider(spaceId)).valueOrNull;
    final hasSuggestedChats =
        suggestedChats?.$1.isNotEmpty == true ||
        suggestedChats?.$2.isNotEmpty == true;
    if (hasSuggestedChats) {
      tabs.add(TabEntry.suggestedChats);
    }
    final suggestedSpaces =
        ref.watch(suggestedSpacesProvider(spaceId)).valueOrNull;
    final hasSuggestedSpaces =
        suggestedSpaces?.$1.isNotEmpty == true ||
        suggestedSpaces?.$2.isNotEmpty == true;
    if (hasSuggestedSpaces) {
      tabs.add(TabEntry.suggestedSpaces);
    }

    final otherChats = ref.watch(otherChatsProvider(spaceId)).valueOrNull;
    final hasChats =
        otherChats?.$1.isNotEmpty == true || otherChats?.$2.isNotEmpty == true;
    if (hasChats) {
      tabs.add(TabEntry.chats);
    }

    final otherSubSpaces =
        ref.watch(otherSubSpacesProvider(spaceId)).valueOrNull;
    final hasOtherSubSpaces =
        otherSubSpaces?.$1.isNotEmpty == true ||
        otherSubSpaces?.$2.isNotEmpty == true;
    if (hasOtherSubSpaces) {
      tabs.add(TabEntry.spaces);
    }

    if (tabs.isEmpty) {
      final error = ref.watch(spaceRelationsProvider(spaceId)).error;
      if (error != null) {
        tabs.add(TabEntry.spacesLoadingError);
      }
    }
    return tabs;
  }

  List<TabEntry> _getActions(String spaceId) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    if (membership == null) {
      return [];
    }
    bool canAddPin = membership.canString('CanPostPin') == true;
    bool canAddEvent = membership.canString('CanPostEvent') == true;
    bool canAddTask = membership.canString('CanPostTaskList') == true;
    bool canLinkSpaces = membership.canString('CanLinkSpaces') == true;

    //Show action menu only if you have at lease one permission
    if (canAddPin | canAddEvent | canAddTask | canLinkSpaces) {
      return [TabEntry.actions];
    }
    return [];
  }
}

final tabsProvider =
    NotifierProvider.family<TabsNotifier, List<TabEntry>, String>(
      () => TabsNotifier(),
    );
