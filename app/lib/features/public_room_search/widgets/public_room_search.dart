import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/types.dart';
import 'package:acter/features/public_room_search/widgets/maybe_direct_room_action_widget.dart';
import 'package:acter/features/public_room_search/widgets/public_room_item.dart';
import 'package:acter/features/public_room_search/widgets/server_selection_field.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  bool hasSearchTerm = false;

  final TextEditingController searchTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final hasSearchTerm = ref.watch(searchFilterProvider).searchTerm != null;
    return SearchBar(
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
      ),
      controller: searchTextController,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Atlas.magnifying_glass),
      ),
      hintText: L10n.of(context).searchSpace,
      trailing: hasSearchTerm
          ? [
              InkWell(
                onTap: () {
                  searchTextController.clear();
                  ref
                      .read(searchFilterProvider.notifier)
                      .updateSearchTerm(null);
                },
                child: const Icon(Icons.clear),
              ),
            ]
          : null,
      onChanged: (value) {
        ref.read(searchFilterProvider.notifier).updateSearchTerm(value);
      },
    );
  }
}

class PublicRoomSearch extends ConsumerWidget {
  final Widget? title;
  final bool autofocus;
  final OnSelectedFn onSelected;

  const PublicRoomSearch({
    super.key,
    this.title,
    this.autofocus = false,
    required this.onSelected,
  });

  Widget _searchBar(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: SizedBox(
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SearchField(),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Row(
                  children: [
                    _filterChipsButtons(context, ref),
                    _serverSelectionBuilder(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChipsButtons(BuildContext context, WidgetRef ref) {
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
      menuStyle: const MenuStyle(visualDensity: VisualDensity.compact),
      onSelected: (FilterBy? newFilter) {
        ref
            .read(searchFilterProvider.notifier)
            .updateFilters(newFilter ?? FilterBy.both);
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
      itemBuilder: (context, item, index) => PublicRoomItem(
        item: item,
        onSelected: (item) =>
            onSelected(item, ref.read(searchFilterProvider).server),
      ),
      pagedBuilder: (controller, builder) => PagedSliverList(
        pagingController: controller,
        builderDelegate: builder,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: title ?? Text(L10n.of(context).joinSpace),
      ),
      body: CustomScrollView(
        slivers: [
          _searchBar(context, ref),
          SliverToBoxAdapter(
            child: MaybeDirectRoomActionWidget(
              searchVal: ref.watch(
                searchFilterProvider.select((v) => v.searchTerm ?? ''),
              ),
              canMatchAlias: true,
              canMatchId: true,
            ),
          ),
          _searchResults(context, ref),
        ],
      ),
    );
  }

  Widget _serverSelectionBuilder(BuildContext context, WidgetRef ref) {
    String? currentSelection = ref.watch(searchFilterProvider).server;
    if (currentSelection != null) {
      final foundEntry = defaultServers
          .where(
            (element) => element.value == currentSelection,
          )
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
          onSelect: (newServer) => ref
              .read(searchFilterProvider.notifier)
              .updateSearchServer(newServer),
        ),
      ),
    );
  }
}
