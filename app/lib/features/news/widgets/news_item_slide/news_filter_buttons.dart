import 'package:acter/features/news/providers/news_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsFilterButtons extends ConsumerWidget {
  const NewsFilterButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return filterChips(ref, lang);
  }

  Widget filterChips(WidgetRef ref, L10n lang) {
    final updateFilter = ref.watch(updateFilterProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilterChip(
          selected: updateFilter == UpdateFilters.all,
          label: Text(lang.all),
          onSelected: (value) =>
              ref.read(updateFilterProvider.notifier).state = UpdateFilters.all,
        ),
        const SizedBox(width: 10),
        FilterChip(
          selected: updateFilter == UpdateFilters.news,
          label: Text(lang.boost),
          onSelected: (value) => ref.read(updateFilterProvider.notifier).state =
              UpdateFilters.news,
        ),
        const SizedBox(width: 10),
        FilterChip(
          selected: updateFilter == UpdateFilters.story,
          label: Text(lang.story),
          onSelected: (value) => ref.read(updateFilterProvider.notifier).state =
              UpdateFilters.story,
        ),
      ],
    );
  }
}
