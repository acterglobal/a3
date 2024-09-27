import 'dart:math';

import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class NewsGridView extends StatelessWidget {
  final List<NewsEntry> newsList;
  final Function(int)? onTapNewItem;

  const NewsGridView({
    super.key,
    required this.newsList,
    this.onTapNewItem,
  });

  @override
  Widget build(BuildContext context) {
    return _buildNewsListGridUI(context);
  }

  Widget _buildNewsListGridUI(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (newsList.isEmpty) return Container();

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(2, min(widthCount, minCount)),
        children: List.generate(
          newsList.length,
          (index) => InkWell(
            onTap: () => onTapNewItem != null ? onTapNewItem!(index) : null,
            child: newsItemUI(newsList[index]),
          ),
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
