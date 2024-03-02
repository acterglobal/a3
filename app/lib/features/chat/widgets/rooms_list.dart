import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/widgets/convo_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

final bucketGlobal = PageStorageBucket();

class RoomsListWidget extends ConsumerStatefulWidget {
  static const roomListMenuKey = Key('room-list');

  const RoomsListWidget({super.key = roomListMenuKey});

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
    if (_isSearchVisible) {
      return Text(
        'Filter chats',
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }

    if (!ref.watch(hasRoomFilters)) {
      return Text(
        AppLocalizations.of(context)!.chat,
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }

    return Text(
      'Filtered chats',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget filterBox(BuildContext context) {
    final selected =
        ref.watch(roomListFilterProvider.select((value) => value.selection));
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
          focusNode: searchFocus,
          controller: searchTextController,
          leading: const Icon(Atlas.magnifying_glass),
          hintText: 'Search chats',
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
        const SizedBox(height: 20),
        SegmentedButton<FilterSelection>(
          segments: const [
            ButtonSegment(
              value: FilterSelection.all,
              label: Text('all'),
            ),
            ButtonSegment(
              value: FilterSelection.favorites,
              icon: Icon(Icons.bookmark_outline),
            ),
            ButtonSegment(
              value: FilterSelection.dmsOnly,
              label: Text("only DM's"),
            ),
          ],
          onSelectionChanged: (Set<FilterSelection> newSelection) async {
            await ref
                .read(roomListFilterProvider.notifier)
                .setSelection(newSelection.first);
          },
          selected: {selected},
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (hasFilters)
              OutlinedButton(
                onPressed: () {
                  searchTextController.clear();
                  ref.read(roomListFilterProvider.notifier).clear();
                  setState(() {
                    _isSearchVisible = false;
                  });
                },
                child: const Text('clear'),
              ),
            if (!hasFilters)
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSearchVisible = false;
                  });
                },
                child: const Text('close'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(alwaysClientProvider);
    final hasFilters = ref.watch(hasRoomFilters);
    final inSideBar = ref.watch(inSideBarProvider);
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: filterBox(context),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          SliverToBoxAdapter(
            child: client.isGuest()
                ? empty
                : ConvosList(
                    onSelected: (String roomId) {
                      inSideBar
                          ? context.goNamed(
                              Routes.chatroom.name,
                              pathParameters: {'roomId': roomId},
                            )
                          : context.pushNamed(
                              Routes.chatroom.name,
                              pathParameters: {'roomId': roomId},
                            );
                    },
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
