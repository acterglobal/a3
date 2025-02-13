import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/related/spaces_helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuggestedSpacesSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const SuggestedSpacesSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedSpaces =
        ref.watch(suggestedSpacesProvider(spaceId)).valueOrNull;

    if (suggestedSpaces == null ||
        (suggestedSpaces.$1.isEmpty && suggestedSpaces.$2.isEmpty)) {
      return SizedBox.shrink();
    }

    return buildSuggestedSpacesSectionUI(
      context,
      ref,
      suggestedSpaces.$1,
      suggestedSpaces.$2,
    );
  }

  Widget buildSuggestedSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> suggestedLocalSpaces,
    List<SpaceHierarchyRoomInfo> suggestedRemoteSpaces,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).suggestedSpaces,
          isShowSeeAllButton: true,
          onTapSeeAll: () => context.pushNamed(
            Routes.subSpaces.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        localSpacesListUI(suggestedLocalSpaces),
        remoteSubSpacesListUI(ref, spaceId, suggestedRemoteSpaces),
      ],
    );
  }
}
