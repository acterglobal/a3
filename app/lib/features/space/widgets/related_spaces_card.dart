import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/relatest_spaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
          L10n.of(context).thereAreNoSpacesRelatedToThisSpace,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Text(L10n.of(context).loadingSpacesFailed(error)),
      ),
      loading: () => SliverToBoxAdapter(child: Text(L10n.of(context).loading)),
    );
  }
}
