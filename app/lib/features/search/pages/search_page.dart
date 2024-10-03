import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/search/providers/search_providers.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          searchBarUI(),
          const SizedBox(height: 12),
          filterChipsButtons(),
        ],
      ),
    );
  }

  Widget searchBarUI() {
    final searchValue = ref.watch(searchValueProvider);
    final hasSearchTerm = searchValue.isNotEmpty;
    return SearchBar(
      controller: searchTextController,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Atlas.magnifying_glass),
      ),
      hintText: L10n.of(context).search,
      trailing: hasSearchTerm
          ? [
              InkWell(
                onTap: () {
                  searchTextController.clear();
                  ref.read(searchValueProvider.notifier).state = '';
                },
                child: const Icon(Icons.clear),
              ),
            ]
          : null,
      onChanged: (value) {
        ref.read(searchValueProvider.notifier).state = value;
      },
    );
  }

  Widget filterChipsButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Wrap(
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
            const SizedBox(width: 10),
            FilterChip(
              selected: searchFilterValue == SearchFilters.events,
              label: Text(L10n.of(context).events),
              onSelected: (value) => ref
                  .read(searchFilterProvider.notifier)
                  .state = SearchFilters.events,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: searchFilterValue == SearchFilters.tasks,
              label: Text(L10n.of(context).tasks),
              onSelected: (value) => ref
                  .read(searchFilterProvider.notifier)
                  .state = SearchFilters.tasks,
            ),
          ],
        ),
      ),
    );
  }
}
