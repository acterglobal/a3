import 'dart:math';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/news/types.dart';
import 'package:acter/features/news/widgets/news_item/news_post_time_widget.dart';
import 'package:acter/features/news/widgets/news_item_slide/news_slide_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NewsGridView extends StatelessWidget {
  final List<UpdateEntry> newsList;
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
    final widthCount = (size.width ~/ 300).toInt();
    const int minCount = 2;

    if (newsList.isEmpty) return Container();

    return SingleChildScrollView(
      child: StaggeredGrid.count(
        crossAxisCount: max(widthCount, minCount),
        children: List.generate(
          newsList.length,
          (index) => InkWell(
            onTap: onTapNewItem.map((cb) => () => cb(index)),
            child: newsItemUI(newsList[index]),
          ),
        ),
      ),
    );
  }

  Widget newsItemUI(UpdateEntry updateEntry) {
    final List<UpdateSlide> newsSlides = updateEntry.slides();
    final slideCount = newsSlides.length;

    if (newsSlides.isEmpty) return const SizedBox.shrink();
    final slide = newsSlides[0];

    return Container(
      height: 300,
      margin: const EdgeInsets.all(6),
      child: Stack(
        children: [
          UpdateSlideItem(slide: slide, showRichContent: false),
          if (slideCount > 1) slideStackCountView(slideCount),
          newsPostTime(updateEntry.originServerTs()),
        ],
      ),
    );
  }

  Widget slideStackCountView(int slideCount) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.stack(), size: 32),
              const SizedBox(width: 4),
              Text(slideCount.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget newsPostTime(int timestamp) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NewsPostTimeWidget(originServerTs: timestamp),
        ),
      ),
    );
  }
}
