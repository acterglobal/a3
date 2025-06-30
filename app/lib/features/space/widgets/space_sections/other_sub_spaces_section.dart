import 'dart:math';

import 'package:acter/features/space/providers/suggested_provider.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/space/widgets/related/spaces_helpers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OtherSubSpacesSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const OtherSubSpacesSection({
    super.key,
    required this.spaceId,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherSubSpaces =
        ref.watch(otherSubSpacesProvider(spaceId)).valueOrNull;

    if (otherSubSpaces == null ||
        (otherSubSpaces.$1.isEmpty && otherSubSpaces.$2.isEmpty)) {
      return SizedBox.shrink();
    }

    return buildOtherSubSpacesSectionUI(
      context,
      ref,
      otherSubSpaces.$1,
      otherSubSpaces.$2,
    );
  }

  Widget buildOtherSubSpacesSectionUI(
    BuildContext context,
    WidgetRef ref,
    List<String> otherLocalSubSpaces,
    List<SpaceHierarchyRoomInfo> otherRemoteSubSpaces,
  ) {
    final localSubSpacesCount = min(limit, otherLocalSubSpaces.length);
    final remoteSubSpacesCount = min(
      (limit - localSubSpacesCount),
      otherRemoteSubSpaces.length,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).spaces,
          isShowSeeAllButton: true,
          onTapSeeAll:
              () => context.pushNamed(
                Routes.subSpaces.name,
                pathParameters: {'spaceId': spaceId},
              ),
        ),
        localSpacesListUI(otherLocalSubSpaces, limit: localSubSpacesCount),
        remoteSubSpacesListUI(
          ref,
          spaceId,
          otherRemoteSubSpaces,
          limit: remoteSubSpacesCount,
        ),
      ],
    );
  }
}
