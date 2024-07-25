import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/scrollable_list_tab_scroller.dart';
import 'package:acter/features/space/dialogs/suggested_rooms.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/space/widgets/skeletons/space_details_skeletons.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter/features/space/widgets/space_sections/chats_section.dart';
import 'package:acter/features/space/widgets/space_sections/events_section.dart';
import 'package:acter/features/space/widgets/space_sections/members_section.dart';
import 'package:acter/features/space/widgets/space_sections/pins_section.dart';
import 'package:acter/features/space/widgets/space_sections/space_actions_section.dart';
import 'package:acter/features/space/widgets/space_sections/spaces_section.dart';
import 'package:acter/features/space/widgets/space_sections/tasks_section.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceDetailsPage extends ConsumerStatefulWidget {
  static const headerKey = Key('space-menus-header');
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
  bool showedSuggested = false;
  ProviderSubscription<AsyncValue<bool>>? suggestionsShowerListener;
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    menuScrollingListeners();
    listenForSuggestions();
  }

  @override
  void didUpdateWidget(SpaceDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      showedSuggested = false;
      suggestionsShowerListener?.close();
      listenForSuggestions();
    }
  }

  void listenForSuggestions() {
    suggestionsShowerListener = ref.listenManual(
      shouldShowSuggestedProvider(widget.spaceId),
      (asyncPrev, asyncNext) {
        final prev = asyncPrev?.valueOrNull ?? false;
        final next = asyncNext.valueOrNull ?? false;

        if (prev == next || !next) {
          // nothing to do
          return;
        }

        if (!showedSuggested) {
          // only show once per room.
          showedSuggested = true;
          showSuggestRoomsDialog(context, ref, widget.spaceId);
        }
      },
    );
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.7),
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
              Theme.of(context).colorScheme.surface.withOpacity(0.1),
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.2, 0.7, 1.0],
            tileMode: TileMode.decal,
          ),
        ),
        child: spaceBodyUI(),
      ),
    );
  }

  Widget spaceBodyUI() {
    final spaceMenus = ref.watch(tabsProvider(widget.spaceId));
    return spaceMenus.when(
      skipLoadingOnReload: true,
      data: (tabsList) {
        return ScrollableListTabScroller(
          headerKey: SpaceDetailsPage.headerKey,
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
      error: (error, stack) => Text(L10n.of(context).loadingFailed(error)),
      loading: () => const SpaceDetailsSkeletons(),
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
                AnimatedContainer(
                  height: showHeader ? null : 0,
                  curve: Curves.easeIn,
                  duration: const Duration(seconds: 1),
                  child: SpaceHeader(spaceIdOrAlias: widget.spaceId),
                ),
                AnimatedContainer(
                  height: !showHeader ? null : 0,
                  curve: Curves.easeOut,
                  duration: const Duration(seconds: 1),
                  child: SpaceToolbar(
                    spaceId: widget.spaceId,
                    spaceTitle: Text(displayName ?? ''),
                  ),
                ),
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
    switch (tabItem.key) {
      case TabEntry.overview:
        return AboutSection(spaceId: widget.spaceId);
      case TabEntry.pins:
        return PinsSection(spaceId: widget.spaceId);
      case TabEntry.tasks:
        return TasksSection(spaceId: widget.spaceId);
      case TabEntry.events:
        return EventsSection(spaceId: widget.spaceId);
      case TabEntry.chatsKey:
        return ChatsSection(spaceId: widget.spaceId);
      case TabEntry.spacesKey:
        return SpacesSection(spaceId: widget.spaceId);
      case TabEntry.membersKey:
        return MembersSection(spaceId: widget.spaceId);
      case TabEntry.actionsKey:
        return SpaceActionsSection(spaceId: widget.spaceId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget spaceTopicUI() {
    return Card(
      child: Container(),
    );
  }
}
