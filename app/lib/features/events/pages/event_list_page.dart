import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_list_empty_state.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventListPage extends ConsumerStatefulWidget {
  final String? spaceId;
  final String? searchQuery;
  final Function(String)? onSelectEventItem;

  const EventListPage({
    super.key,
    this.spaceId,
    this.searchQuery,
    this.onSelectEventItem,
  });

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  ValueNotifier<EventFilters> eventFilters =
      ValueNotifier<EventFilters>(EventFilters.all);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      ref.read(eventListSearchTermProvider(widget.spaceId).notifier).state =
          widget.searchQuery ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final spaceId = widget.spaceId;
    return AppBar(
      centerTitle: false,
      title: widget.onSelectEventItem != null
          ? Text(L10n.of(context).selectEvent)
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).events),
                if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
              ],
            ),
      actions: [
        if (widget.onSelectEventItem == null)
          AddButtonWithCanPermission(
            canString: 'CanPostEvent',
            spaceId: widget.spaceId,
            onPressed: () => context.pushNamed(
              Routes.createEvent.name,
              queryParameters: {'spaceId': widget.spaceId},
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          initialText: widget.searchQuery,
          onChanged: (value) {
            ref
                .read(eventListSearchTermProvider(widget.spaceId).notifier)
                .state = value;
          },
          onClear: () {
            ref
                .read(eventListSearchTermProvider(widget.spaceId).notifier)
                .state = '';
          },
        ),
        ValueListenableBuilder(
          valueListenable: eventFilters,
          builder: (context, eventFilter, child) => filterChipsButtons(),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: eventFilters,
            builder: (context, eventFilter, child) => eventListUI(),
          ),
        ),
      ],
    );
  }

  Widget filterChipsButtons() {
    final lang = L10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        child: Wrap(
          children: [
            FilterChip(
              selected: eventFilters.value == EventFilters.all,
              label: Text(lang.all),
              onSelected: (value) => eventFilters.value = EventFilters.all,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilters.value == EventFilters.bookmarked,
              label: Text(lang.bookmarked),
              onSelected: (value) =>
                  eventFilters.value = EventFilters.bookmarked,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilters.value == EventFilters.ongoing,
              label: Text(lang.happeningNow),
              onSelected: (value) => eventFilters.value = EventFilters.ongoing,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilters.value == EventFilters.upcoming,
              label: Text(lang.upcoming),
              onSelected: (value) => eventFilters.value = EventFilters.upcoming,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilters.value == EventFilters.past,
              label: Text(lang.past),
              onSelected: (value) => eventFilters.value = EventFilters.past,
            ),
          ],
        ),
      ),
    );
  }

  Widget eventListUI() {
    final isEmptyList =
        ref.watch(isEmptyEventList(widget.spaceId)).valueOrNull == true;

    if (isEmptyList) {
      return EventListEmptyState(
        spaceId: widget.spaceId,
        isSearchApplied:
            ref.read(eventListSearchTermProvider(widget.spaceId)).isNotEmpty,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eventFilters.value == EventFilters.bookmarked)
            EventListWidget(
              isShowSpaceName: widget.spaceId == null,
              onTapEventItem: widget.onSelectEventItem,
              listProvider: bookmarkedEventListProvider(widget.spaceId),
            ),
          if (eventFilters.value == EventFilters.all ||
              eventFilters.value == EventFilters.ongoing)
            EventListWidget(
              isShowSpaceName: widget.spaceId == null,
              onTapEventItem: widget.onSelectEventItem,
              listProvider:
                  allOngoingEventListWithSearchProvider(widget.spaceId),
            ),
          if (eventFilters.value == EventFilters.all) SizedBox(height: 20),
          if (eventFilters.value == EventFilters.all ||
              eventFilters.value == EventFilters.upcoming)
            EventListWidget(
              isShowSpaceName: widget.spaceId == null,
              onTapEventItem: widget.onSelectEventItem,
              listProvider:
                  allUpcomingEventListWithSearchProvider(widget.spaceId),
            ),
          if (eventFilters.value == EventFilters.all) SizedBox(height: 20),
          if (eventFilters.value == EventFilters.all ||
              eventFilters.value == EventFilters.past)
            EventListWidget(
              isShowSpaceName: widget.spaceId == null,
              onTapEventItem: widget.onSelectEventItem,
              listProvider: allPastEventListWithSearchProvider(widget.spaceId),
            ),
        ],
      ),
    );
  }
}
