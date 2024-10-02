import 'dart:math';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::sections::news');

class NewsSection extends ConsumerWidget {
  final String spaceId;
  final int limit;

  const NewsSection({
    super.key,
    required this.spaceId,
    this.limit = 4,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsLoader = ref.watch(newsListProvider(spaceId));
    return newsLoader.when(
      data: (news) => buildNewsSectionUI(context, news),
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

  Widget buildNewsSectionUI(BuildContext context, List<NewsEntry> news) {
    final hasMore = news.length > limit;
    final count = hasMore ? limit : news.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: L10n.of(context).updates,
          isShowSeeAllButton: hasMore,
          onTapSeeAll: () => context.pushNamed(
            Routes.spaceUpdates.name,
            pathParameters: {'spaceId': spaceId},
          ),
        ),
        _buildNewsListGridUI(context, news, count),
      ],
    );
  }

  Widget _buildNewsListGridUI(
    BuildContext context,
    List<NewsEntry> updateList,
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

  Widget newsItemUI(BuildContext context, NewsEntry newsEntry) {
    final List<NewsSlide> newsSlides = newsEntry.slides().toList();
    final slide = newsSlides[0];

    return InkWell(
      onTap: () => context.pushNamed(
        Routes.spaceUpdates.name,
        pathParameters: {'spaceId': spaceId},
      ),
      child: Container(
        height: 100,
        margin: const EdgeInsets.all(6),
        child: NewsSlideItem(slide: slide, showRichContent: false),
      ),
    );
  }
}
