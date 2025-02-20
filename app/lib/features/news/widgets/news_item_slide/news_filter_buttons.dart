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
        ToggleButtons(
          borderRadius: BorderRadius.circular(25),
          selectedColor: Theme.of(context).primaryColor,
          fillColor: Colors.white.withValues(alpha: 0.7),
          isSelected: UpdateFilters.values
              .map((filter) => filter == updateFilter)
              .toList(),
          onPressed: (index) {
            ref.read(updateFilterProvider.notifier).state =
                UpdateFilters.values[index];
          },
          children: UpdateFilters.values.map((filter) {
            switch (filter) {
              case UpdateFilters.all:
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(lang.all),
                );
              case UpdateFilters.news:
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(lang.boost),
                );
              case UpdateFilters.story:
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(lang.story),
                );
            }
          }).toList(),
        ),
      ],
    );
  }
}
