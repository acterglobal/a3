import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RecommendedSpaceCard extends ConsumerWidget {
  final String spaceId;

  const RecommendedSpaceCard({super.key, required this.spaceId});

  List<Widget> renderRecommendations(
    BuildContext context,
    String spaceIdOrAlias,
    SpaceRelationsOverview spaces, {
    int crossAxisCount = 1,
  }) {
    if (spaces.otherRelations.isEmpty) {
      return const [SizedBox.shrink()];
    }

    return [
      if (spaces.otherRelations.isNotEmpty)
        Row(
          children: [
            Text(
              L10n.of(context).spaces,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      if (spaces.otherRelations.isNotEmpty)
        GridView.builder(
          itemCount: spaces.otherRelations.length,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 4.0,
            mainAxisExtent: 100,
          ),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final space = spaces.otherRelations[index];
            return SpaceCard(
              key: Key('other-related-list-item-${space.getRoomIdStr()}'),
              space: space,
            );
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spaceRelationsOverviewProvider(spaceId));

    return spaces.when(
      data: (spaces) => SingleChildScrollView(
        child: Column(
          children: renderRecommendations(context, spaceId, spaces),
        ),
      ),
      error: (error, stack) =>
          Text(L10n.of(context).loadingSpacesFailed(error)),
      loading: () => Text(L10n.of(context).loading),
    );
  }
}
