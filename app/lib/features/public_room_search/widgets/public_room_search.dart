import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter/features/public_room_search/widgets/maybe_direct_room_action_widget.dart';
import 'package:acter/features/public_room_search/widgets/public_room_item.dart';
import 'package:acter/features/public_room_search/widgets/server_selection_field.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PublicRoomSearch extends ConsumerStatefulWidget {
  final bool autofocus;
  final OnSelectedFn onSelected;
  final String? initialQuery;

  const PublicRoomSearch({
    super.key,
    this.autofocus = false,
    this.initialQuery,
    required this.onSelected,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PublicRoomSearchState();
}

class _PublicRoomSearchState extends ConsumerState<PublicRoomSearch> {
  @override
  void initState() {
    super.initState();
    _checkInitialQuery();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _checkInitialQuery();
  }

  void _checkInitialQuery() {
    widget.initialQuery.map((p0) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(searchFilterProvider.notifier).updateSearchTerm(p0);
      });
    });
  }

  Widget _searchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: SizedBox(
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ActerSearchWidget(
                initialText: widget.initialQuery,
                padding: EdgeInsets.zero,
                hintText: L10n.of(context).jumpTo,
                onChanged: (String value) {
                  final notifier = ref.read(searchFilterProvider.notifier);
                  notifier.updateSearchTerm(value);
                },
                onClear: () {
                  final notifier = ref.read(searchFilterProvider.notifier);
                  notifier.updateSearchTerm(null);
                },
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Row(
                  children: [
                    _filterBy(context),
                    _serverSelectionBuilder(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBy(BuildContext context) {
    final selected =
        ref.watch(searchFilterProvider.select((value) => value.filterBy));
    return DropdownMenu<FilterBy>(
      initialSelection: selected,
      // requestFocusOnTap is enabled/disabled by platforms when it is null.
      // On mobile platforms, this is false by default. Setting this to true will
      // trigger focus request on the text field and virtual keyboard will appear
      // afterward. On desktop platforms however, this defaults to true.
      requestFocusOnTap: true,
      enableSearch: false,
      label: const Text('Show only'),
      textStyle: TextStyle(color: Theme.of(context).hintColor),
      menuStyle: const MenuStyle(visualDensity: VisualDensity.compact),
      onSelected: (FilterBy? newFilter) {
        final notifier = ref.read(searchFilterProvider.notifier);
        notifier.updateFilters(newFilter ?? FilterBy.both);
      },
      dropdownMenuEntries: const [
        DropdownMenuEntry<FilterBy>(
          value: FilterBy.both,
          label: 'All',
        ),
        DropdownMenuEntry<FilterBy>(
          value: FilterBy.spaces,
          label: 'Spaces',
        ),
        DropdownMenuEntry<FilterBy>(
          value: FilterBy.chats,
          label: 'Chats',
        ),
      ],
    );
  }

  Widget _searchResults(BuildContext context, WidgetRef ref) {
    return RiverPagedBuilder<Next?, PublicSearchResultItem>.autoDispose(
      firstPageKey: const Next(isStart: true),
      provider: publicSearchProvider,
      // pullToRefresh: true,
      firstPageProgressIndicatorBuilder: (context, controller) =>
          loadingPage(context),
      itemBuilder: (context, item, index) => PublicRoomItem(
        item: item,
        onSelected: (item) {
          final serverName = ref.read(searchFilterProvider).server;
          return widget.onSelected(item, serverName);
        },
      ),
      noItemsFoundIndicatorBuilder: (context, controller) {
        if (ref.read(publicSearchProvider.notifier).isLoading()) {
          return loadingPage(context);
        }
        return nothingFound(context);
      },
      pagedBuilder: (controller, builder) => PagedSliverList(
        pagingController: controller,
        builderDelegate: builder,
      ),
    );
  }

  Widget nothingFound(BuildContext context) {
    return Center(
      child: Text(L10n.of(context).searchPublicDirectoryNothingFound),
    );
  }

  Widget loadingPage(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: List.generate(
        5,
        (index) => Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Bone.square(size: 30),
                    title: Skeletonizer(
                      child: Text(
                        'nothing',
                        style: textTheme.labelLarge,
                        softWrap: false,
                      ),
                    ),
                    subtitle: Skeletonizer(
                      child: Text(
                        'some larger subtitle',
                        style: textTheme.labelSmall,
                        softWrap: false,
                      ),
                    ),
                    trailing: Skeletonizer(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('join'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String buildSearchTitle(BuildContext context) {
    final lang = L10n.of(context);
    return switch (ref.watch(searchFilterProvider).filterBy) {
      FilterBy.spaces => lang.searchSpaces,
      FilterBy.chats => lang.searchChats,
      FilterBy.both => lang.searchPublicDirectory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final searchVal =
        ref.watch(searchFilterProvider.select((v) => v.searchTerm ?? ''));
    return Scaffold(
      appBar: AppBar(
        title: Text(buildSearchTitle(context)),
      ),
      body: CustomScrollView(
        slivers: [
          _searchBar(context),
          SliverToBoxAdapter(
            child: MaybeDirectRoomActionWidget(
              searchVal: searchVal,
              canMatchAlias: true,
              canMatchId: true,
            ),
          ),
          _searchResults(context, ref),
        ],
      ),
    );
  }

  Widget _serverSelectionBuilder(BuildContext context) {
    String? currentSelection = ref.watch(searchFilterProvider).server;
    if (currentSelection != null) {
      final foundEntry = defaultServers
          .where((element) => element.value == currentSelection)
          .firstOrNull;
      if (foundEntry != null) {
        currentSelection = foundEntry.name ?? foundEntry.value;
      }
    }
    return Flexible(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: ServerSelectionField(
          options: defaultServers,
          autofocus: true,
          currentSelection: currentSelection ?? 'Acter.global',
          onSelect: (newServer) {
            final notifier = ref.read(searchFilterProvider.notifier);
            notifier.updateSearchServer(newServer);
          },
        ),
      ),
    );
  }
}
