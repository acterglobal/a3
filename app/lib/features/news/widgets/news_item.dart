import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/text_slide.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class NewsItem extends ConsumerStatefulWidget {
  final Client client;
  final NewsEntry news;
  final int index;
  final PageController pageController;

  const NewsItem({
    super.key,
    required this.client,
    required this.news,
    required this.index,
    required this.pageController,
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
                  bgColor: bgColor,
                  fgColor: fgColor,
                );

              case 'video':
                return VideoSlide(
                  slide: slides[idx],
                  bgColor: bgColor,
                  fgColor: fgColor,
                );

              case 'text':
                return TextSlide(
                  slide: slides[idx],
                  bgColor: bgColor,
                  fgColor: fgColor,
                  pageController: widget.pageController,
                );

              default:
                return Expanded(
                  child: Center(
                    child: Text(
                      L10n.of(context).slidesNotYetSupported(slideType),
                    ),
                  ),
                );
            }
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 60, bottom: 20),
              child: newsActionButtons(newsSlide: slides[currentSlideIndex]),
            ),
            InkWell(
              onTap: () => goToSpace(context, roomId),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: space.when(
                  data: (space) =>
                      Text(space.spaceProfileData.displayName ?? roomId),
                  error: (e, st) => Text(L10n.of(context).errorLoadingSpace(e)),
                  loading: () => Skeletonizer(
                    child: Text(roomId),
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: NewsSideBar(
            news: widget.news,
            index: widget.index,
          ),
        ),
        Positioned.fill(
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

  Widget newsActionButtons({
    required NewsSlide newsSlide,
  }) {
    final newsReferencesList = newsSlide.references().toList();
    if (newsReferencesList.isEmpty) return const SizedBox();

    final referenceDetails = newsReferencesList.first.refDetails();
    final uriId = referenceDetails.uri() ?? '';
    final title = referenceDetails.title() ?? '';

    if (title == NewsReferencesType.shareEvent.name) {
      return ref.watch(calendarEventProvider(uriId)).when(
            data: (calendarEvent) {
              return EventItem(
                event: calendarEvent,
              );
            },
            loading: () => const EventItemSkeleton(),
            error: (e, s) =>
                Center(child: Text(L10n.of(context).failedToLoadEvent(e))),
          );
    } else {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(L10n.of(context).unsupportedPleaseUpgrade),
        ),
      );
    }
  }
}
