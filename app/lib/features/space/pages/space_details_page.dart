import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/widgets/space_details/about_section.dart';
import 'package:acter/features/space/widgets/chats_card.dart';
import 'package:acter/features/space/widgets/related_spaces/sub_spaces_card.dart';
import 'package:acter/features/space/widgets/space_details/events_section.dart';
import 'package:acter/features/space/widgets/space_details/pins_section.dart';
import 'package:acter/features/space/widgets/space_details/tasks_section.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:scrollable_list_tab_scroller/scrollable_list_tab_scroller.dart';

class SpaceDetailsPage extends ConsumerStatefulWidget {
  final String spaceId;

  const SpaceDetailsPage({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends ConsumerState<SpaceDetailsPage> {
  ValueNotifier<bool> showHeader = ValueNotifier<bool>(true);
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    menuScrollingListeners();
  }

  void menuScrollingListeners() {
    itemPositionsListener.itemPositions.addListener(() {
      var value = itemPositionsListener.itemPositions;
      if (value.value.first.index == 0 &&
          value.value.first.itemLeadingEdge == 0) {
        showHeader.value = true;
      } else {
        showHeader.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: spaceBodyUI(),
    );
  }

  Widget spaceBodyUI() {
    final spaceMenus = ref.watch(tabsProvider(widget.spaceId));
    return spaceMenus.when(
      skipLoadingOnReload: true,
      data: (tabsList) {
        return ScrollableListTabScroller(
          itemCount: tabsList.length,
          itemPositionsListener: itemPositionsListener,

          //Space Details Header UI
          headerContainerBuilder:
              (BuildContext context, Widget menuBarWidget) =>
                  spaceHeaderUI(menuBarWidget),

          //Space Details Tab Menu UI
          tabBuilder: (BuildContext context, int index, bool active) =>
              spaceTabMenuUI(tabsList[index], active),

          //Space Details Page UI
          itemBuilder: (BuildContext context, int index) =>
              spacePageUI(tabsList[index]),
        );
      },
      error: (error, stack) => Container(),
      loading: () => Container(),
    );
  }

  Widget spaceHeaderUI(Widget menuBarWidget) {
    final displayName =
        ref.watch(roomDisplayNameProvider(widget.spaceId)).valueOrNull;

    return Column(
      children: [
        //Header Content UI
        ValueListenableBuilder(
          valueListenable: showHeader,
          builder: (context, showHeader, child) {
            return Stack(
              children: [
                AnimatedSizeAndFade(
                  sizeDuration: const Duration(milliseconds: 700),
                  child: showHeader
                      ? SpaceHeader(spaceIdOrAlias: widget.spaceId)
                      : const SizedBox.shrink(),
                ),
                !showHeader
                    ? SpaceToolbar(
                        spaceId: widget.spaceId,
                        spaceTitle: Text(displayName ?? ''),
                      )
                    : const SizedBox.shrink(),
              ],
            );
          },
        ),
        //Append menu bar widget
        menuBarWidget,
      ],
    );
  }

  Widget spaceAvatar() {
    final avatarData =
        ref.watch(roomAvatarProvider(widget.spaceId)).valueOrNull;
    if (avatarData != null) {
      return Image.memory(
        avatarData.bytes,
        height: 300,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
      );
    } else {
      return Container(height: 200, color: Colors.red);
    }
  }

  Widget spaceTabMenuUI(TabEntry tabItem, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(tabItem.label),
    );
  }

  Widget spacePageUI(TabEntry tabItem) {
    if (tabItem.key == TabEntry.overview) {
      return AboutSection(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.pins) {
      return PinsSection(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.tasks) {
      return TasksSection(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.events) {
      return EventsSection(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.chatsKey) {
      return ChatsCard(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.spacesKey) {
      return SubSpacesCard(spaceId: widget.spaceId);
    } else if (tabItem.key == TabEntry.membersKey) {
      return const SizedBox(
        height: 300,
        child: Text('Space Members'),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget spaceTopicUI() {
    return Card(
      child: Container(),
    );
  }
}
