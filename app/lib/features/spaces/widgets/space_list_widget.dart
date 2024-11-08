import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/spaces/widgets/space_list_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space-list-widget');

class SpaceListWidget extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<Space>>> spaceListProvider;
  final int? limit;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final bool shrinkWrap;
  final Widget emptyState;

  const SpaceListWidget({
    super.key,
    required this.spaceListProvider,
    this.limit,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceLoader = ref.watch(spaceListProvider);
    return spaceLoader.when(
      data: (spaceList) => buildSpaceSectionUI(context, spaceList),
      error: (error, stack) => spaceListErrorWidget(context, ref, error, stack),
      loading: () => const SpaceListSkeleton(),
      skipLoadingOnReload: true,
    );
  }

  Widget spaceListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load spaces', error, stack);
    return ErrorPage(
      background: const SpaceListSkeleton(),
      error: error,
      stack: stack,
      textBuilder: L10n.of(context).loadingFailed,
      onRetryTap: () {
        ref.invalidate(spaceListProvider);
      },
    );
  }

  Widget buildSpaceSectionUI(BuildContext context, List<Space> spaceList) {
    if (spaceList.isEmpty) return emptyState;

    final count = (limit ?? spaceList.length).clamp(0, spaceList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: L10n.of(context).spaces,
                isShowSeeAllButton: count < spaceList.length,
                onTapSeeAll: onClickSectionHeader.map((cb) => () => cb()),
              ),
              spaceListUI(spaceList, count),
            ],
          )
        : spaceListUI(spaceList, count);
  }

  Widget spaceListUI(List<Space> spaceList, int count) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return RoomCard(roomId: spaceList[index].getRoomIdStr());
      },
    );
  }
}
