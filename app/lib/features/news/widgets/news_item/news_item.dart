import 'dart:core';

import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/news/widgets/news_item/news_post_time_widget.dart';
import 'package:acter/features/news/widgets/news_item/news_side_bar.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsItem extends ConsumerStatefulWidget {
  final NewsEntry news;

  const NewsItem({super.key, required this.news});

  @override
  ConsumerState<NewsItem> createState() => _NewsItemState();
}

class _NewsItemState extends ConsumerState<NewsItem> {
  final ValueNotifier<int> currentSlideIndex = ValueNotifier(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    currentSlideIndex.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.news.slides().toList();

    return Stack(
      children: [
        buildSlidesUI(slides),
        buildSpaceNameAndPostTime(),
        NewsSideBar(news: widget.news),
        buildSelectedSlideIndicators(slides.length),
      ],
    );
  }

  Widget buildSlidesUI(List<NewsSlide> slides) {
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: slides.length,
      onPageChanged: (page) => currentSlideIndex.value = page,
      itemBuilder: (context, index) => NewsSlideItem(slide: slides[index]),
    );
  }

  Widget buildSpaceNameAndPostTime() {
    final roomId = widget.news.roomId().toString();

    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => goToSpace(context, roomId),
              child: SpaceNameWidget(spaceId: roomId, isShowBrackets: false),
            ),
            NewsPostTimeWidget(originServerTs: widget.news.originServerTs()),
          ],
        ),
      ),
    );
  }

  Widget buildSelectedSlideIndicators(int slideCount) {
    return Positioned.fill(
      child: slideCount <= 1
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder(
                valueListenable: currentSlideIndex,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: CarouselIndicator(
                      count: slideCount,
                      index: value,
                      width: 10,
                      height: 10,
                    ),
                  );
                },
              ),
            ),
    );
  }
}
