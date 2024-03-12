import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/relatest_spaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RelatedSpacesCard extends ConsumerWidget {
  final String spaceId;

  const RelatedSpacesCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceId));

    return spaces.when(
      data: (spaces) => RelatedSpaces(
        spaceIdOrAlias: spaceId,
        spaces: spaces,
        showParents: false,
        fallback: Text(
          'There are no spaces related to this space',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Text('Loading spaces failed: $error'),
      ),
      loading: () => const SliverToBoxAdapter(child: Text('Loading')),
    );
  }
}
