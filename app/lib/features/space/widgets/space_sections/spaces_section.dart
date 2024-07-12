import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/space/widgets/related_spaces/helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

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
        spaceRelationsOverview.hasMoreSubspaces,
      ),
      error: (error, stack) =>
          Center(child: Text(L10n.of(context).loadingFailed(error))),
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<Space> spaces,
    bool hasMore,
  ) {
    int spacesLimit = (spaces.length > limit) ? limit : spaces.length;
    int renderMoreCount = limit > spaces.length ? limit - spaces.length : 0;
    bool isShowSeeAllButton = (spaces.length > spacesLimit) || hasMore;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).spaces,
          isShowSeeAllButton: isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceRelatedSpaces.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        spacesListUI(spaces, spacesLimit),
        if (renderMoreCount > 0 && hasMore)
          renderMoreSubspaces(
            context,
            ref,
            spaceId,
            maxLength: renderMoreCount,
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget spacesListUI(List<Space> spaces, int spacesLimit) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: spacesLimit,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final space = spaces[index];
        return SpaceCard(
          key: Key('subspace-list-item-${space.getRoomIdStr()}'),
          space: space,
          showParents: false,
        );
      },
    );
  }
}
