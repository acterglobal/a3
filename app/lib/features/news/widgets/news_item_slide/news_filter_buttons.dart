import 'package:acter/features/news/providers/news_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsFilterButtons extends ConsumerWidget {
  const NewsFilterButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final updateFilter = ref.watch(updateFilterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFilterToggleButtons(context, ref, updateFilter, lang),
      ],
    );
  }

  Widget _buildFilterToggleButtons(
    BuildContext context,
    WidgetRef ref,
    UpdateFilters updateFilter,
    L10n lang,
  ) {
    return ToggleButtons(
      isSelected:
          UpdateFilters.values.map((filter) => filter == updateFilter).toList(),
      fillColor: Colors.transparent,
      borderColor: Colors.transparent,
      selectedBorderColor: Colors.transparent,
      selectedColor: Colors.white,
      color: Colors.white54,
      renderBorder: false,
      onPressed: (index) {
        ref.read(updateFilterProvider.notifier).state =
            UpdateFilters.values[index];
      },
      children: UpdateFilters.values
          .map((filter) => _buildFilterButton(filter, lang))
          .toList(),
    );
  }

  Widget _buildFilterButton(UpdateFilters filter, L10n lang) {
    return Row(
      children: [
        _buildFilterText(filter, lang),
        if (filter != UpdateFilters.story) _buildDivider(),
      ],
    );
  }

  Widget _buildFilterText(UpdateFilters filter, L10n lang) {
    return Text(
      _getFilterText(filter, lang),
      style: TextStyle(
        shadows: [
          Shadow(
            offset: const Offset(1, 1),
            blurRadius: 1.0,
            color: Colors.black.withValues(alpha: .3),
          ),
        ],
      ),
    );
  }

  String _getFilterText(UpdateFilters filter, L10n lang) {
    switch (filter) {
      case UpdateFilters.all:
        return lang.all;
      case UpdateFilters.news:
        return lang.boost;
      case UpdateFilters.story:
        return lang.story;
    }
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        height: 15,
        width: 1,
        color: Colors.grey,
      ),
    );
  }
}
