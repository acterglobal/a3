import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_list_skeleton_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/search/providers/search.dart';

class EventListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const EventListPage({super.key, this.spaceId});

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  final TextEditingController searchTextController = TextEditingController();

  String get searchValue => ref.watch(searchValueProvider);

  EventFilters get eventFilterValue => ref.watch(eventFilerProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).events),
          if (widget.spaceId != null) _buildSpaceName(),
        ],
      ),
      actions: [
        AddButtonWithCanPermission(
          canString: 'CanPostEvent',
          onPressed: () => context.pushNamed(
            Routes.createEvent.name,
            queryParameters: {'spaceId': widget.spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceName() {
    String spaceName =
        ref.watch(roomDisplayNameProvider(widget.spaceId!)).valueOrNull ?? '';
    return Text(
      '($spaceName)',
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  Widget _buildBody() {
    AsyncValue<List<CalendarEvent>> eventList;
    eventList = ref.watch(
      eventListSearchFilterProvider(
        (spaceId: widget.spaceId, searchText: searchValue),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        filterChipsButtons(),
        Expanded(
          child: eventList.when(
            data: (events) => _buildEventList(events),
            error: (error, stack) =>
                Center(child: Text(L10n.of(context).loadingFailed(error))),
            loading: () => const EventListSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Atlas.magnifying_glass),
        ),
        hintText: L10n.of(context).search,
        trailing: searchValue.isNotEmpty
            ? [
                IconButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(searchValueProvider.notifier).state = '';
                    searchTextController.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ]
            : null,
        onChanged: (value) =>
            ref.read(searchValueProvider.notifier).state = value,
      ),
    );
  }

  Widget filterChipsButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            FilterChip(
              selected: eventFilterValue == EventFilters.all,
              label: Text(L10n.of(context).all),
              onSelected: (value) => ref
                  .read(eventFilerProvider.notifier)
                  .state = EventFilters.all,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.ongoing,
              label: Text(L10n.of(context).ongoing),
              onSelected: (value) => ref
                  .read(eventFilerProvider.notifier)
                  .state = EventFilters.ongoing,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.upcoming,
              label: Text(L10n.of(context).upcoming),
              onSelected: (value) => ref
                  .read(eventFilerProvider.notifier)
                  .state = EventFilters.upcoming,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.past,
              label: Text(L10n.of(context).past),
              onSelected: (value) => ref
                  .read(eventFilerProvider.notifier)
                  .state = EventFilters.past,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<CalendarEvent> events) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (events.isEmpty) return _buildEventsEmptyState();

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(1, min(widthCount, minCount)),
        children: [
          for (var event in events) EventItem(event: event),
        ],
      ),
    );
  }

  Widget _buildEventsEmptyState() {
    bool canAdd = false;
    if (searchValue.isEmpty) {
      canAdd = ref
              .watch(hasSpaceWithPermissionProvider('CanPostEvent'))
              .valueOrNull ??
          false;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: searchValue.isNotEmpty
            ? L10n.of(context).noMatchingPinsFound
            : L10n.of(context).noPinsAvailableYet,
        subtitle: L10n.of(context).noPinsAvailableDescription,
        image: 'assets/images/empty_pin.svg',
        primaryButton: canAdd && searchValue.isEmpty
            ? ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(
                  Routes.actionAddPin.name,
                  queryParameters: {'spaceId': widget.spaceId},
                ),
                child: Text(L10n.of(context).createPin),
              )
            : null,
      ),
    );
  }
}
