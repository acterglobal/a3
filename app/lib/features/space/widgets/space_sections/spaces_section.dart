import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/space/widgets/related/spaces_helpers.dart';
import 'package:acter/features/space/widgets/related/util.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
    final lang = L10n.of(context);
    final suggestedSpaces =
        ref.watch(suggestedSpacesProvider(spaceId)).valueOrNull;
    if (suggestedSpaces != null &&
        (suggestedSpaces.$1.isNotEmpty || suggestedSpaces.$2.isNotEmpty)) {
      return buildSuggestedSpacesSectionUI(
        context,
        ref,
        suggestedSpaces.$1,
        suggestedSpaces.$2,
      );
    }

    final overviewLoader = ref.watch(spaceRelationsOverviewProvider(spaceId));
    return overviewLoader.when(
      data: (overview) => buildSpacesSectionUI(
        context,
        ref,
        overview.knownSubspaces,
      ),
      error: (e, s) {
        _log.severe('Failed to load the related spaces', e, s);
        return Center(
          child: Text(lang.loadingSpacesFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(lang.loading),
      ),
    );
  }

  Widget buildSuggestedSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> suggestedLocalSpaces,
    List<SpaceHierarchyRoomInfo> suggestedRemoteSpaces,
  ) {
    final config = calculateSectionConfig(
      localListLen: suggestedLocalSpaces.length,
      limit: limit,
      remoteListLen: suggestedRemoteSpaces.length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).spaces,
          isShowSeeAllButton: true,
          onTapSeeAll: () => context.pushNamed(
            Routes.subSpaces.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        spacesListUI(
          suggestedLocalSpaces,
          config.listingLimit,
          // showOptions: false,
          // showSuggestedMarkIfGiven: false,
        ),
        if (config.renderRemote)
          renderRemoteSubspaces(
            context,
            ref,
            spaceId,
            suggestedRemoteSpaces,
            maxLength: config.remoteCount,
          ),
      ],
    );
  }

  Widget buildSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> spaces,
  ) {
    final subspaces = ref.watch(remoteSubspaceRelationsProvider(spaceId));
    final config = calculateSectionConfig(
      localListLen: spaces.length,
      limit: limit,
      remoteListLen: (subspaces.valueOrNull ?? []).length,
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).spaces,
          isShowSeeAllButton: config.isShowSeeAllButton,
          onTapSeeAll: () => context.pushNamed(
            Routes.subSpaces.name,
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
        return RoomCard(
          key: Key('subspace-list-item-$roomId'),
          roomId: roomId,
          showParents: false,
          showVisibilityMark: true,
        );
      },
    );
  }
}
