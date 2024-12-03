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
        filterChipsButtons(),
        Expanded(
          child: EventListWidget(
            isShowSpaceName: widget.spaceId == null,
            shrinkWrap: false,
            onTapEventItem: widget.onSelectEventItem,
            listProvider: eventListSearchedAndFilterProvider(widget.spaceId),
            emptyStateBuilder: () => EventListEmptyState(
              spaceId: widget.spaceId,
              isSearchApplied: ref
                  .read(eventListSearchTermProvider(widget.spaceId))
                  .isNotEmpty,
            ),
          ),
        ),
      ],
    );
  }

  Widget filterChipsButtons() {
    final lang = L10n.of(context);
    final currentFilter = ref.watch(eventListFilterProvider(widget.spaceId));
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
              selected: currentFilter == EventFilters.all,
              label: Text(lang.all),
              onSelected: (value) => ref
                  .read(eventListFilterProvider(widget.spaceId).notifier)
                  .state = EventFilters.all,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: currentFilter == EventFilters.bookmarked,
              label: Text(lang.bookmarked),
              onSelected: (value) => ref
                  .read(eventListFilterProvider(widget.spaceId).notifier)
                  .state = EventFilters.bookmarked,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: currentFilter == EventFilters.ongoing,
              label: Text(lang.happeningNow),
              onSelected: (value) => ref
                  .read(eventListFilterProvider(widget.spaceId).notifier)
                  .state = EventFilters.ongoing,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: currentFilter == EventFilters.upcoming,
              label: Text(lang.upcoming),
              onSelected: (value) => ref
                  .read(eventListFilterProvider(widget.spaceId).notifier)
                  .state = EventFilters.upcoming,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: currentFilter == EventFilters.past,
              label: Text(lang.past),
              onSelected: (value) => ref
                  .read(eventListFilterProvider(widget.spaceId).notifier)
                  .state = EventFilters.past,
            ),
          ],
        ),
      ),
    );
  }
}
