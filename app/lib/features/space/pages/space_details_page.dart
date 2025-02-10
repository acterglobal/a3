import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/scrollable_list_tab_scroller.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:acter/features/space/dialogs/suggested_rooms.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/features/space/widgets/skeletons/space_details_skeletons.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter/features/space/widgets/space_sections/chats_section.dart';
import 'package:acter/features/space/widgets/space_sections/members_section.dart';
import 'package:acter/features/space/widgets/space_sections/news_section.dart';
import 'package:acter/features/space/widgets/space_sections/space_actions_section.dart';
import 'package:acter/features/space/widgets/space_sections/spaces_section.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final _log = Logger('a3::space::space_details');

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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.7),
              colorScheme.surface.withOpacity(0.5),
              colorScheme.surface.withOpacity(0.1),
              colorScheme.secondaryContainer,
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
    final tabsLoader = ref.watch(tabsProvider(widget.spaceId));
    return tabsLoader.when(
      skipLoadingOnReload: true,
      data: (tabs) {
        return ScrollableListTabScroller(
          headerKey: SpaceDetailsPage.headerKey,
          itemCount: tabs.length,
          itemPositionsListener: itemPositionsListener,

          //Space Details Header UI
          headerContainerBuilder: (context, menuBarWidget) =>
              spaceHeaderUI(menuBarWidget),

          //Space Details Tab Menu UI
          tabBuilder: (context, index, active) =>
              spaceTabMenuUI(context, tabs[index], active),

          //Space Details Page UI
          itemBuilder: (context, index) => spacePageUI(tabs[index]),

          // we allow this to be refreshed by over-pulling
          onRefresh: () async {
            await Future.wait([
              ref.refresh(spaceProvider(widget.spaceId).future),
              ref.refresh(maybeRoomProvider(widget.spaceId).future),
            ]);
          },
        );
      },
      error: (e, s) => loadingError(e, s),
      loading: () => const SpaceDetailsSkeletons(),
    );
  }

  Widget loadingError(Object error, StackTrace stack) {
    _log.severe('Failed to load tabs in space', error, stack);
    return ErrorPage(
      background: const SpaceDetailsSkeletons(),
      error: error,
      stack: stack,
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () {
        ref.invalidate(spaceProvider(widget.spaceId));
      },
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
          builder: (context, showHeader, child) => Stack(
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
          ),
        ),
        //Append menu bar widget
        menuBarWidget,
      ],
    );
  }

  Widget spaceAvatar() {
    final avatarData =
        ref.watch(roomAvatarProvider(widget.spaceId)).valueOrNull;
    if (avatarData == null) {
      return Container(
        height: 200,
        color: Colors.red,
      );
    }
    return Image.memory(
      avatarData.bytes,
      height: 300,
      width: MediaQuery.of(context).size.width,
      fit: BoxFit.cover,
    );
  }

  Widget spaceTabMenuUI(BuildContext context, TabEntry tabItem, bool active) {
    return Container(
      key: Key(tabItem.name),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      margin: const EdgeInsets.only(
        left: 12,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: active ? Theme.of(context).colorScheme.primary : null,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(itemLabel(context, tabItem)),
    );
  }

  String itemLabel(BuildContext context, TabEntry tabItem) {
    final lang = L10n.of(context);
    return switch (tabItem) {
      TabEntry.overview => lang.overview,
      TabEntry.pins => lang.pins,
      TabEntry.tasks => lang.tasks,
      TabEntry.events => lang.events,
      TabEntry.news => lang.boosts,
      TabEntry.chats => lang.chats,
      TabEntry.spaces => lang.spaces,
      TabEntry.members => lang.members,
      TabEntry.actions => '...',
    };
  }

  Widget spacePageUI(TabEntry tabItem) {
    return switch (tabItem) {
      TabEntry.overview => AboutSection(spaceId: widget.spaceId),
      TabEntry.news => NewsSection(spaceId: widget.spaceId),
      TabEntry.pins => PinListWidget(
          pinListProvider: pinsProvider(widget.spaceId),
          spaceId: widget.spaceId,
          showSectionHeader: true,
          limit: 3,
          onClickSectionHeader: () => context.pushNamed(
            Routes.spacePins.name,
            pathParameters: {'spaceId': widget.spaceId},
          ),
        ),
      TabEntry.tasks => TaskListWidget(
          taskListProvider: taskListsProvider(widget.spaceId),
          spaceId: widget.spaceId,
          showSectionHeader: true,
          limit: 3,
          onClickSectionHeader: () => context.pushNamed(
            Routes.spaceTasks.name,
            pathParameters: {'spaceId': widget.spaceId},
          ),
        ),
      TabEntry.events => EventListWidget(
          isShowSpaceName: false,
          showSectionHeader: true,
          listProvider: allEventSorted(widget.spaceId),
          limit: 3,
          onClickSectionHeader: () => context.pushNamed(
            Routes.spaceEvents.name,
            pathParameters: {'spaceId': widget.spaceId},
          ),
        ),
      TabEntry.chats => ChatsSection(spaceId: widget.spaceId),
      TabEntry.spaces => SpacesSection(spaceId: widget.spaceId),
      TabEntry.members => MembersSection(spaceId: widget.spaceId),
      TabEntry.actions => SpaceActionsSection(spaceId: widget.spaceId),
    };
  }
}
