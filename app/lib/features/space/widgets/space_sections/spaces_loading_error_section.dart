import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/skeletons/room_card_skeleton.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpacesLoadingSection extends ConsumerWidget {
  final String spaceId;

  const SpacesLoadingSection({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(spaceRelationsProvider(spaceId));
    if (currentState.isLoading) {
      return buildFrame(context, [
        RoomCardSkeleton(),
        RoomCardSkeleton(),
        RoomCardSkeleton(),
      ]);
    }
    final error = currentState.error;
    if (error != null) {
      return buildFrame(context, [
        ActerErrorDialog(
          error: error,
          includeBugReportButton: true,
          title: L10n.of(context).joinError,
          onRetryTap: () {
            ref.invalidate(spaceRelationsProvider(spaceId));
          },
          borderRadius: 15.0,
        ),
      ]);
    }

    return SizedBox.shrink();
  }

  Widget buildFrame(BuildContext context, List<Widget> children) => Column(
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
      ...children,
    ],
  );
}
