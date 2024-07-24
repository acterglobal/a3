import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_card.dart';
import 'package:acter/features/space/widgets/related_spaces/helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
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
    List<String> spaces,
  ) {
    int spacesLimit;
    bool isShowSeeAllButton = false;
    bool renderRemote = false;
    int moreCount;
    if (spaces.length > limit) {
      spacesLimit = limit;
      isShowSeeAllButton = true;
      moreCount = 0;
    } else {
      spacesLimit = spaces.length;
      moreCount = limit - spaces.length;
      if (moreCount > 0) {
        // we have space for more
        final remoteCount =
            (ref.watch(remoteSubspaceRelationsProvider(spaceId)).valueOrNull ??
                    [])
                .length;
        if (remoteCount > 0) {
          renderRemote = true;
          if (remoteCount < moreCount) {
            moreCount = remoteCount;
          }
          if (remoteCount > moreCount) {
            isShowSeeAllButton = true;
          }
        }
      }
    }
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
        if (renderRemote)
          renderMoreSubspaces(
            context,
            ref,
            spaceId,
            maxLength: moreCount,
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
          key: Key('subspace-list-item-$roomId}'),
          roomId: roomId,
          showParents: false,
        );
      },
    );
  }
}
