import 'dart:core';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter/features/news/widgets/news_item_slide/text_slide.dart';
import 'package:acter/features/news/widgets/news_side_bar.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:carousel_indicator/carousel_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::news_item');

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
  final ValueNotifier<int> currentSlideIndex = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    final roomId = widget.news.roomId().toString();
    final space = ref.watch(briefSpaceItemProvider(roomId));
    final slides = widget.news.slides().toList();

    return Stack(
      children: [
        PageView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: slides.length,
          onPageChanged: (page) {
            currentSlideIndex.value = page;
          },
          itemBuilder: (context, index) {
            final slide = slides[index];
            final slideType = slide.typeStr();
            final bgColor = getBackgroundColor(slide);
            final fgColor = getForegroundColor(slide);
            return switch (slideType) {
              'image' => ImageSlide(
                  slide: slide,
                  bgColor: bgColor,
                  fgColor: fgColor,
                ),
              'video' => VideoSlide(
                  slide: slide,
                  bgColor: bgColor,
                  fgColor: fgColor,
                ),
              'text' => TextSlide(
                  slide: slide,
                  bgColor: bgColor,
                  fgColor: fgColor,
                  pageController: widget.pageController,
                ),
              _ => Expanded(
                  child: Center(
                    child:
                        Text(L10n.of(context).slidesNotYetSupported(slideType)),
                  ),
                ),
            };
          },
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 60, bottom: 20),
              child:
                  newsActionButtons(newsSlide: slides[currentSlideIndex.value]),
            ),
            InkWell(
              onTap: () => goToSpace(context, roomId),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(space.avatarInfo.displayName ?? roomId),
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
              child: ValueListenableBuilder(
                valueListenable: currentSlideIndex,
                builder: (context, value, child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: CarouselIndicator(
                      count: slides.length,
                      index: value,
                      width: 10,
                      height: 10,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color getBackgroundColor(NewsSlide newsSlide) {
    final color = newsSlide.colors();
    return convertColor(
      color?.background(),
      Theme.of(context).colorScheme.surface,
    );
  }

  Color getForegroundColor(NewsSlide newsSlide) {
    final color = newsSlide.colors();
    return convertColor(
      color?.color(),
      Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget newsActionButtons({required NewsSlide newsSlide}) {
    final newsReferencesList = newsSlide.references().toList();
    if (newsReferencesList.isEmpty) return const SizedBox();
    final referenceDetails = newsReferencesList.first.refDetails();
    return renderActionButton(referenceDetails);
  }

  Widget renderActionButton(RefDetails referenceDetails) {
    final evtType = NewsReferencesType.fromStr(referenceDetails.typeStr());

    return switch (evtType) {
      NewsReferencesType.calendarEvent => renderCalendarEventAction(
          targetEventId: referenceDetails.targetIdStr() ?? '',
        ),
      NewsReferencesType.link => renderLinkActionButtion(referenceDetails),
      _ => renderNotSupportedAction()
    };
  }

  Widget renderLinkActionButtion(RefDetails referenceDetails) {
    final uri = referenceDetails.uri();
    if (uri == null) {
      // malformatted
      return renderNotSupportedAction();
    }
    if (referenceDetails.title() == 'shareEvent' && uri.startsWith('\$')) {
      // fallback support for older, badly formatted calendar events.
      return renderCalendarEventAction(targetEventId: uri);
    }

    final title = referenceDetails.title();
    if (title != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.link),
          onTap: () => openLink(uri, context),
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          subtitle: Text(
            uri,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      return Card(
        child: ListTile(
          leading: const Icon(Atlas.link),
          onTap: () => openLink(uri, context),
          title: Text(
            uri,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      );
    }
  }

  Widget renderCalendarEventAction({required String targetEventId}) {
    final calEventLoader = ref.watch(calendarEventProvider(targetEventId));
    return calEventLoader.when(
      data: (calEvent) => EventItem(event: calEvent),
      loading: () => const EventItemSkeleton(),
      error: (e, s) {
        _log.severe('Failed to load cal event', e, s);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(L10n.of(context).eventNoLongerAvailable),
            subtitle: Text(
              L10n.of(context).eventDeletedOrFailedToLoad,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () async {
              await ActerErrorDialog.show(
                context: context,
                error: e,
                stack: s,
              );
            },
          ),
        );
      },
    );
  }

  Widget renderNotSupportedAction() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(L10n.of(context).unsupportedPleaseUpgrade),
      ),
    );
  }
}
