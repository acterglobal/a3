import 'dart:math';

import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter/features/news/widgets/news_vertical_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::update::list');

class NewsListPage extends ConsumerStatefulWidget {
  final String? spaceId;

  const NewsListPage({super.key, this.spaceId});

  @override
  ConsumerState<NewsListPage> createState() => _NewsListPageState();
}

class _NewsListPageState extends ConsumerState<NewsListPage> {
  final ValueNotifier<bool> gridMode = ValueNotifier(false);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final spaceId = widget.spaceId;
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).updates),
          if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
        ],
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: gridMode,
          builder: (context, value, child) {
            return IconButton(
              onPressed: () {
                gridMode.value = !gridMode.value;
                currentIndex.value = 0;
              },
              icon: value
                  ? const Icon(Icons.fullscreen)
                  : const Icon(Icons.grid_view),
            );
          },
        ),
        AddButtonWithCanPermission(
          canString: 'CanPostNews',
          onPressed: () => context.pushNamed(
            Routes.actionAddUpdate.name,
            queryParameters: {'spaceId': widget.spaceId},
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final newsListLoader = ref.watch(newsListProvider(widget.spaceId));

    return newsListLoader.when(
      data: (updateList) {
        return ValueListenableBuilder(
          valueListenable: gridMode,
          builder: (context, value, child) {
            return value
                ? _buildNewsListGridUI(updateList)
                : NewsVerticalView(
                    newsList: updateList,
                    initialPageIndex: currentIndex.value,
                  );
          },
        );
      },
      error: (error, stack) {
        _log.severe('Failed to load updates', error, stack);
        return ErrorPage(
          background: Container(),
          error: error,
          stack: stack,
          textBuilder: L10n.of(context).loadingFailed,
          onRetryTap: () {},
        );
      },
      loading: () => Container(),
    );
  }

  Widget _buildNewsListGridUI(List<NewsEntry> updateList) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (updateList.isEmpty) return Container();

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(2, min(widthCount, minCount)),
        children: List.generate(
          updateList.length,
          (index) => InkWell(
              onTap: () {
                gridMode.value = !gridMode.value;
                currentIndex.value = index;
              },
              child: newsItemUI(updateList[index])),
        ),
      ),
    );
  }

  Widget newsItemUI(NewsEntry newsEntry) {
    final List<NewsSlide> newsSlides = newsEntry.slides().toList();
    final slide = newsSlides[0];

    return Container(
      height: 300,
      margin: const EdgeInsets.all(6),
      child: NewsSlideItem(slide: slide, showRichContent: false),
    );
  }
}
