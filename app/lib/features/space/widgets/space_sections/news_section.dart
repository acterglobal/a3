import 'dart:math';

import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::news');

class NewsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const NewsSection({super.key, required this.spaceId, this.limit = 4});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final updateLoader = ref.watch(updateListProvider(spaceId));
    return updateLoader.when(
      data: (updateList) => buildNewsSectionUI(context, updateList),
      error: (e, s) {
        _log.severe('Failed to load boosts in space', e, s);
        return Center(child: Text(lang.loadingFailed(e)));
      },
      loading: () => Center(child: Text(lang.loading)),
    );
  }

  Widget buildNewsSectionUI(
    BuildContext context,
    List<UpdateEntry> updateList,
  ) {
    final hasMore = updateList.length > limit;
    final count = hasMore ? limit : updateList.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).boosts,
          isShowSeeAllButton: hasMore,
          onTapSeeAll:
              () => context.pushNamed(
                Routes.spaceUpdates.name,
                pathParameters: {'spaceId': spaceId},
              ),
        ),
        _buildNewsListGridUI(context, updateList, count),
      ],
    );
  }

  Widget _buildNewsListGridUI(
    BuildContext context,
    List<UpdateEntry> updateList,
    int count,
  ) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    final hasMore = updateList.length > limit;
    final count = hasMore ? limit : updateList.length;

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(4, min(widthCount, minCount)),
        children: List.generate(
          count,
          (index) => newsItemUI(context, updateList[index]),
        ),
      ),
    );
  }

  Widget newsItemUI(BuildContext context, UpdateEntry updateEntry) {
    if (updateEntry.slidesCount() == 0) return const SizedBox.shrink();
    final newsSlides = updateEntry.slides().toList();
    final slide = newsSlides[0];

    return InkWell(
      onTap:
          () => context.pushNamed(
            Routes.spaceUpdates.name,
            pathParameters: {'spaceId': spaceId},
          ),
      child: Container(
        height: 100,
        margin: const EdgeInsets.all(6),
        child: UpdateSlideItem(
          slide: slide,
          showRichContent: false,
          errorState: NewsMediaErrorState.showErrorImageOnly,
        ),
      ),
    );
  }
}
