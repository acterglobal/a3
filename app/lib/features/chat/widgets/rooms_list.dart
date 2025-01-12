import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/widgets/chats_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

final bucketGlobal = PageStorageBucket();

typedef RoomSelectAction = Function(String);

class RoomsListWidget extends ConsumerStatefulWidget {
  static const roomListMenuKey = Key('chat-room-list');
  static const openSearchActionButtonKey =
      Key('chat-rooms-list-open-search-action-btn');
  static const closeSearchActionButtonKey =
      Key('chat-rooms-list-close-search-action-btn');

  final RoomSelectAction onSelected;

  const RoomsListWidget({
    required this.onSelected,
    super.key = roomListMenuKey,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => RoomsListWidgetState();
}

class RoomsListWidgetState extends ConsumerState<RoomsListWidget> {
  final ScrollController controller = ScrollController();
  final FocusNode searchFocus = FocusNode();

  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onScroll);
  }

  void _onScroll() {
    final topPosition = controller.position.pixels <= 0;
    final outOfRange = controller.position.outOfRange;
    final offset = controller.offset;
    if (topPosition && outOfRange && offset <= -80) {
      setState(() => _isSearchVisible = true);
    } else if (!topPosition && !outOfRange) {
      setState(() => _isSearchVisible = false);
    }
  }

  Widget roomListTitle(BuildContext context) {
    final lang = L10n.of(context);
    String? title;

    if (ref.watch(hasRoomFilters)) {
      final selection =
          ref.watch(roomListFilterProvider.select((value) => value.selection));
      title = switch (selection) {
        FilterSelection.dmsOnly => lang.dms,
        FilterSelection.favorites => lang.bookmarked,
        _ => null,
      };
    }

    return Text(
      title ?? lang.chat,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget searchTerms(BuildContext context) {
    final searchTerm =
        ref.watch(roomListFilterProvider.select((value) => value.searchTerm));
    if (searchTerm != null && searchTerm.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(L10n.of(context).searchResultFor(searchTerm)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget filterBox(BuildContext context) {
    final searchTerm = ref.watch(roomListFilterProvider).searchTerm;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        ActerSearchWidget(
          initialText: searchTerm,
          padding: EdgeInsets.zero,
          hintText: L10n.of(context).searchChats,
          onChanged: (String value) {
            ref.read(roomListFilterProvider.notifier).updateSearchTerm(value);
          },
          onClear: () {
            ref.read(roomListFilterProvider.notifier).updateSearchTerm(null);
          },
        ),
        filterChipsButtons(),
      ],
    );
  }

  Widget filterChipsButtons() {
    final lang = L10n.of(context);
    final selected =
        ref.watch(roomListFilterProvider.select((value) => value.selection));
    return Container(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        children: [
          FilterChip(
            selected: selected == FilterSelection.all,
            label: Text(lang.all),
            onSelected: (value) async {
              final notifier = ref.read(roomListFilterProvider.notifier);
              await notifier.setSelection(FilterSelection.all);
            },
          ),
          const SizedBox(width: 10),
          FilterChip(
            selected: selected == FilterSelection.favorites,
            label: Text(lang.bookmarked),
            onSelected: (value) async {
              final notifier = ref.read(roomListFilterProvider.notifier);
              await notifier.setSelection(FilterSelection.favorites);
            },
          ),
          const SizedBox(width: 10),
          FilterChip(
            selected: selected == FilterSelection.dmsOnly,
            label: Text(lang.dms),
            onSelected: (value) async {
              final notifier = ref.read(roomListFilterProvider.notifier);
              await notifier.setSelection(FilterSelection.dmsOnly);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageStorage(
      bucket: bucketGlobal,
      child: Column(
        children: [
          Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(15),
                  child: roomListTitle(context),
                ),
                leadingWidth: double.infinity,
                actions: renderActions(),
              ),
              AnimatedOpacity(
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
              searchTerms(context),
            ],
          ),
          Expanded(
            child: ref.watch(isGuestProvider)
                ? empty
                : ChatsList(
                    onSelected: (roomId) {
                      ref.read(roomListFilterProvider.notifier).clear();
                      setState(() => _isSearchVisible = false);
                      widget.onSelected(roomId);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> renderActions() {
    final hasFilters = ref.watch(hasRoomFilters);
    if (_isSearchVisible) {
      return [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: RoomsListWidget.closeSearchActionButtonKey,
                onPressed: () {
                  setState(() => _isSearchVisible = false);
                },
                child: Text(L10n.of(context).close),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      if (!hasFilters)
        IconButton(
          key: RoomsListWidget.openSearchActionButtonKey,
          onPressed: () {
            setState(() {
              _isSearchVisible = true;
              searchFocus.requestFocus();
            });
          },
          padding: const EdgeInsets.only(
            right: 10,
            left: 5,
          ),
          icon: const Icon(Atlas.magnifying_glass),
        ),
      if (hasFilters)
        IconButton(
          key: RoomsListWidget.openSearchActionButtonKey,
          onPressed: () {
            setState(() => _isSearchVisible = true);
          },
          padding: const EdgeInsets.only(
            right: 10,
            left: 5,
          ),
          icon: Badge(
            backgroundColor: Theme.of(context).colorScheme.badgeImportant,
            child: const Icon(Atlas.filter_thin),
          ),
        ),
      PlusIconWidget(
        onPressed: () => context.pushNamed(Routes.createChat.name),
      ),
    ];
  }

  Widget get empty {
    return Center(
      child: SvgPicture.asset('assets/images/empty_messages.svg'),
    );
  }
}
