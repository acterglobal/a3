import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpacesSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const SpacesSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        spacesLabel(context),
        spacesList(context, ref),
      ],
    );
  }

  Widget spacesLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            L10n.of(context).spaces,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () {},
            child: Text(L10n.of(context).seeAll),
          ),
        ],
      ),
    );
  }

  Widget spacesList(BuildContext context, WidgetRef ref) {
    final spacesList = ref.watch(spaceRelationsOverviewProvider(spaceId));

    return spacesList.when(
      data: (spaces) {
        int spacesLimit = (spaces.knownSubspaces.length > limit) ? limit : spaces.knownSubspaces.length;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: spacesLimit,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final space = spaces.knownSubspaces[index];
            return SpaceCard(
              key: Key('subspace-list-item-${space.getRoomIdStr()}'),
              space: space,
              showParents: false,
            );
          },
        );
      },
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }
}