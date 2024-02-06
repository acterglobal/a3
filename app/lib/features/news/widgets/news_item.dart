import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/text_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsItem extends ConsumerStatefulWidget {
  final Client client;
  final NewsEntry news;
  final int index;
  const NewsItem({
    super.key,
    required this.client,
    required this.news,
    required this.index,
  });

  @override
  ConsumerState<NewsItem> createState() => _NewsItemState();
}

class _NewsItemState extends ConsumerState<NewsItem> {
  int currentSlideIndex = 0;

  @override
  Widget build(BuildContext context) {
    final roomId = widget.news.roomId().toString();
    final space = ref.watch(briefSpaceItemProvider(roomId));
    final slides = widget.news.slides().toList();
    final color = slides[currentSlideIndex].colors();
    final bgColor = convertColor(
      color?.background(),
      Theme.of(context).colorScheme.background,
    );
    final fgColor = convertColor(
      color?.color(),
      Theme.of(context).colorScheme.onPrimary,
    );

    return Stack(
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: slides.length,
          onPageChanged: (page) {
            currentSlideIndex = page;
            setState(() {});
          },
          itemBuilder: (context, idx) {
            final slideType = slides[idx].typeStr();
            switch (slideType) {
              case 'image':
                return ImageSlide(
                  slide: slides[idx],
                );

              case 'video':
                return VideoSlide(
                  slide: slides[idx],
                );

              case 'text':
                return TextSlide(
                  slide: slides[idx],
                  bgColor: bgColor,
                  fgColor: fgColor,
                );

              default:
                return Expanded(
                  child: Center(
                    child: Text('$slideType slides not yet supported'),
                  ),
                );
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 80, bottom: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  context.pushNamed(
                    Routes.space.name,
                    pathParameters: {'spaceId': roomId},
                  );
                },
                child: space.when(
                  data: (space) =>
                      Text(space!.spaceProfileData.displayName ?? roomId),
                  error: (e, st) => Text('Error loading space: $e'),
                  loading: () => Skeletonizer(
                    child: Text(roomId),
                  ),
                ),
              ),
              Text(
                slides[currentSlideIndex].text(),
                softWrap: true,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: fgColor,
                  shadows: [
                    Shadow(
                      color: bgColor,
                      offset: const Offset(1, 1),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: NewsSideBar(
            news: widget.news,
            index: widget.index,
          ),
        ),
        Positioned.fill(
          bottom: 50,
          child: Visibility(
            visible: slides.length > 1,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: CarouselIndicator(
                  count: slides.length,
                  index: currentSlideIndex,
                  width: 10,
                  height: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
