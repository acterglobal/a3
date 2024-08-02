import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/space/widgets/related/spaces_helpers.dart';
import 'package:acter/features/space/widgets/related/util.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::spaces');

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
    final spacesList = ref.watch(spaceRelationsOverviewProvider(spaceId));
    return spacesList.when(
      data: (spaceRelationsOverview) => buildSpacesSectionUI(
        context,
        ref,
        spaceRelationsOverview.knownSubspaces,
      ),
      error: (error, stack) {
        _log.severe('Fetching of related spaces failed', error, stack);
        return Center(child: Text(L10n.of(context).loadingFailed(error)));
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> spaces,
  ) {
    final config = calculateSectionConfig(
      localListLen: spaces.length,
      limit: limit,
      remoteListLen:
          (ref.watch(remoteSubspaceRelationsProvider(spaceId)).valueOrNull ??
                  [])
              .length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).spaces,
          isShowSeeAllButton: config.isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceRelatedSpaces.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        spacesListUI(spaces, config.listingLimit),
        if (config.renderRemote)
          renderMoreSubspaces(
            context,
            ref,
            spaceId,
            maxLength: config.remoteCount,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget spacesListUI(List<String> spaces, int spacesLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: spacesLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final roomId = spaces[index];
        return SpaceCard(
          key: Key('subspace-list-item-$roomId'),
          roomId: roomId,
          showParents: false,
        );
      },
    );
  }
}
