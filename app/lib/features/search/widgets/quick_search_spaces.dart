import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/room/room_card.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::quick_search::spaces');

class QuickSearchSpaces extends ConsumerWidget {
  final int limit;

  const QuickSearchSpaces({
    super.key,
    this.limit = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceLoader = ref.watch(searchedSpacesProvider);
    return spaceLoader.when(
      data: (spaceList) => buildSpacesSectionUI(context, spaceList),
      error: (e, s) {
        _log.severe('Failed to load pins in space', e, s);
        return Center(
          child: Text(L10n.of(context).loadingFailed(e)),
        );
      },
      loading: () => Center(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget buildSpacesSectionUI(BuildContext context, List<String> spaceList) {
    final hasMore = spaceList.length > limit;
    final count = hasMore ? limit : spaceList.length;
    return spaceList.isEmpty
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: L10n.of(context).spaces,
                isShowSeeAllButton: hasMore,
                onTapSeeAll: () => context.pushNamed(Routes.spaces.name),
              ),
              spaceListUI(spaceList, count),
            ],
          );
  }

  Widget spaceListUI(List<String> spaceList, int count) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return RoomCard(
          roomId: spaceList[index],
        );
      },
    );
  }
}
