import 'package:acter/common/providers/common_providers.dart';
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

  const EventListPage({
    super.key,
    this.spaceId,
  });

  @override
  ConsumerState<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends ConsumerState<EventListPage> {
  String get searchValue => ref.watch(searchValueProvider);

  EventFilters get eventFilterValue => ref.watch(eventFilterProvider);

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
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).events),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
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
          onChanged: (value) {
            final notifier = ref.read(searchValueProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(searchValueProvider.notifier);
            notifier.state = '';
          },
        ),
        filterChipsButtons(),
        Expanded(
          child: EventListWidget(
            spaceId: widget.spaceId,
            shrinkWrap: false,
            searchValue: searchValue,
            emptyState: EventListEmptyState(
              spaceId: widget.spaceId,
              isSearchApplied: searchValue.isNotEmpty,
            ),
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
              selected: eventFilterValue == EventFilters.all,
              label: Text(lang.all),
              onSelected: (value) {
                final notifier = ref.read(eventFilterProvider.notifier);
                notifier.state = EventFilters.all;
              },
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.bookmarked,
              label: Text(lang.bookmarked),
              onSelected: (value) {
                final notifier = ref.read(eventFilterProvider.notifier);
                notifier.state = EventFilters.bookmarked;
              },
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.ongoing,
              label: Text(lang.happeningNow),
              onSelected: (value) {
                final notifier = ref.read(eventFilterProvider.notifier);
                notifier.state = EventFilters.ongoing;
              },
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.upcoming,
              label: Text(lang.upcoming),
              onSelected: (value) {
                final notifier = ref.read(eventFilterProvider.notifier);
                notifier.state = EventFilters.upcoming;
              },
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: eventFilterValue == EventFilters.past,
              label: Text(lang.past),
              onSelected: (value) {
                final notifier = ref.read(eventFilterProvider.notifier);
                notifier.state = EventFilters.past;
              },
            ),
          ],
        ),
      ),
    );
  }
}
