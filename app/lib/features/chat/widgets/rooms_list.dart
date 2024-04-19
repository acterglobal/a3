import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/widgets/convo_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

final bucketGlobal = PageStorageBucket();

class RoomsListWidget extends ConsumerStatefulWidget {
  final Function(String) onSelected;
  static const roomListMenuKey = Key('room-list');

  const RoomsListWidget({
    required this.onSelected,
    super.key = roomListMenuKey,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RoomsListWidgetState();
}

class _RoomsListWidgetState extends ConsumerState<RoomsListWidget> {
  final ScrollController controller = ScrollController();
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
    searchTextController.text =
        ref.read(roomListFilterProvider).searchTerm ?? '';
  }

  @override
  void didUpdateWidget(RoomsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    searchTextController.text =
        ref.read(roomListFilterProvider).searchTerm ?? '';
  }

  void _onScroll() {
    final topPosition = controller.position.pixels <= 0;
    final outOfRange = controller.position.outOfRange;
    final offset = controller.offset;
    if (topPosition && outOfRange && offset <= -80) {
      setState(() {
        _isSearchVisible = true;
      });
    } else if (!topPosition && !outOfRange) {
      setState(() {
        _isSearchVisible = false;
      });
    }
  }

  Widget roomListTitle(BuildContext context) {
    String title = L10n.of(context).chat;

    if (ref.watch(hasRoomFilters)) {
      final selection =
          ref.watch(roomListFilterProvider.select((value) => value.selection));
      switch (selection) {
        case FilterSelection.dmsOnly:
          title = L10n.of(context).dms;
          break;
        case FilterSelection.favorites:
          title = L10n.of(context).bookmarked;
        default:
          break;
      }
    }

    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget searchTerms(BuildContext context) {
    String searchFilterText = '';

    final searchTerm =
        ref.watch(roomListFilterProvider.select((value) => value.searchTerm));
    if (searchTerm != null && searchTerm.isNotEmpty) {
      searchFilterText = L10n.of(context).searchResultFor(searchTerm);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(searchFilterText),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget filterBox(BuildContext context) {
    final hasSearchTerm = ref
            .watch(roomListFilterProvider.select((value) => value.searchTerm))
            ?.isNotEmpty ==
        true;
    final hasFilters = ref.watch(hasRoomFilters);
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        SearchBar(
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          focusNode: searchFocus,
          controller: searchTextController,
          leading: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Atlas.magnifying_glass),
          ),
          hintText: L10n.of(context).searchChats,
          trailing: hasSearchTerm
              ? [
                  InkWell(
                    onTap: () {
                      searchTextController.clear();
                      ref
                          .read(roomListFilterProvider.notifier)
                          .updateSearchTerm(null);
                    },
                    child: const Icon(Icons.clear),
                  ),
                ]
              : null,
          onChanged: (value) {
            ref.read(roomListFilterProvider.notifier).updateSearchTerm(value);
          },
        ),
        filterChipsButtons(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasFilters)
              TextButton(
                onPressed: () {
                  searchTextController.clear();
                  ref.read(roomListFilterProvider.notifier).clear();
                  setState(() {
                    _isSearchVisible = false;
                  });
                },
                child: Text(L10n.of(context).clear),
              ),
            if (!hasFilters)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = false;
                  });
                },
                child: Text(L10n.of(context).close),
              ),
          ],
        ),
      ],
    );
  }

  Widget filterChipsButtons() {
    final selected =
        ref.watch(roomListFilterProvider.select((value) => value.selection));
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          FilterChip(
            selected: selected == FilterSelection.all,
            label: Text(L10n.of(context).all),
            onSelected: (value) async {
              await ref
                  .read(roomListFilterProvider.notifier)
                  .setSelection(FilterSelection.all);
            },
          ),
          const SizedBox(width: 10),
          FilterChip(
            selected: selected == FilterSelection.favorites,
            label: Text(L10n.of(context).bookmarked),
            onSelected: (value) async {
              await ref
                  .read(roomListFilterProvider.notifier)
                  .setSelection(FilterSelection.favorites);
            },
          ),
          const SizedBox(width: 10),
          FilterChip(
            selected: selected == FilterSelection.dmsOnly,
            label: Text(L10n.of(context).dms),
            onSelected: (value) async {
              await ref
                  .read(roomListFilterProvider.notifier)
                  .setSelection(FilterSelection.dmsOnly);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(alwaysClientProvider);
    final hasFilters = ref.watch(hasRoomFilters);
    return PageStorage(
      bucket: bucketGlobal,
      child: CustomScrollView(
        controller: controller,
        key: const PageStorageKey<String>('convo-list'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverLayoutBuilder(
            builder: (context, constraints) {
              return SliverAppBar(
                automaticallyImplyLeading: false,
                floating: true,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(15),
                  child: roomListTitle(context),
                ),
                leadingWidth: double.infinity,
                actions: _isSearchVisible
                    ? []
                    : [
                        if (!hasFilters)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSearchVisible = true;
                                searchFocus.requestFocus();
                              });
                            },
                            padding: const EdgeInsets.only(right: 10, left: 5),
                            icon: const Icon(Atlas.magnifying_glass),
                          ),
                        if (hasFilters)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _isSearchVisible = true;
                              });
                            },
                            padding: const EdgeInsets.only(right: 10, left: 5),
                            icon: Badge(
                              backgroundColor:
                                  Theme.of(context).colorScheme.badgeImportant,
                              child: const Icon(Atlas.filter_thin),
                            ),
                          ),
                        IconButton(
                          onPressed: () async => context.pushNamed(
                            Routes.createChat.name,
                          ),
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          icon: const Icon(
                            Atlas.plus_circle_thin,
                          ),
                        ),
                      ],
              );
            },
          ),
          SliverToBoxAdapter(
            child: AnimatedOpacity(
              opacity: !_isSearchVisible ? 0 : 1,
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 400),
              child: _isSearchVisible
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: filterBox(context),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: searchTerms(context),
          ),
          SliverToBoxAdapter(
            child: client.isGuest()
                ? empty
                : ConvosList(
                    onSelected: widget.onSelected,
                  ),
          ),
        ],
      ),
    );
  }

  SvgPicture get empty {
    return SvgPicture.asset('assets/images/empty_messages.svg');
  }
}
