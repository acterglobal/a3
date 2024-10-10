import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:acter/features/search/providers/search_providers.dart';
import 'package:acter/features/search/widgets/quick_search_spaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final searchTextController = TextEditingController();

  SearchFilters get searchFilterValue => ref.watch(searchFilterProvider);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBodyUI()),
    );
  }

  Widget _buildBodyUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActerSearchWidget(searchTextController: searchTextController),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: filterChipsButtons(),
          ),
          if (searchFilterValue == SearchFilters.all ||
              searchFilterValue == SearchFilters.spaces)
            const QuickSearchSpaces(),
          if (searchFilterValue == SearchFilters.all ||
              searchFilterValue == SearchFilters.pins)
            PinListWidget(
              limit: 3,
              showSectionHeader: true,
              onClickSectionHeader: () => context.pushNamed(Routes.pins.name),
            ),
        ],
      ),
    );
  }

  Widget filterChipsButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            FilterChip(
              selected: searchFilterValue == SearchFilters.all,
              label: Text(L10n.of(context).all),
              onSelected: (value) => ref
                  .read(searchFilterProvider.notifier)
                  .state = SearchFilters.all,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: searchFilterValue == SearchFilters.spaces,
              label: Text(L10n.of(context).spaces),
              onSelected: (value) => ref
                  .read(searchFilterProvider.notifier)
                  .state = SearchFilters.spaces,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: searchFilterValue == SearchFilters.pins,
              label: Text(L10n.of(context).pins),
              onSelected: (value) => ref
                  .read(searchFilterProvider.notifier)
                  .state = SearchFilters.pins,
            ),
          ],
        ),
      ),
    );
  }
}
