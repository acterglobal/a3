import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item/news_item.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preload_page_view/preload_page_view.dart';

class NewsFullView extends ConsumerStatefulWidget {
  final List<UpdateEntry> updateList;
  final int initialPageIndex;

  const NewsFullView({
    super.key,
    required this.updateList,
    this.initialPageIndex = 0,
  });

  @override
  ConsumerState<NewsFullView> createState() => NewsVerticalViewState();
}

class NewsVerticalViewState extends ConsumerState<NewsFullView> {
  static PreloadPageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController =
        PreloadPageController(initialPage: widget.initialPageIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _pageController = null;
    super.dispose();
  }

  static void goToPage(int index) {
    _pageController?.animateToPage(
      index,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildPagerView();
  }

  Widget buildPagerView() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      child: PreloadPageView.builder(
        controller: _pageController,
        itemCount: widget.updateList.length,
        scrollDirection: Axis.vertical,
        preloadPagesCount:
            widget.updateList.length > 5 ? 5 : widget.updateList.length,
        itemBuilder: (context, index) {
          return InkWell(
            onDoubleTap: () async {
              LikeAnimation.run(index);
              final news = widget.updateList[index];
              final manager =
                  await ref.read(updateReactionsProvider(news).future);
              final status = manager.likedByMe();
              if (!status) {
                await manager.sendLike();
              }
            },
            child: NewsItem(updateEntry: widget.updateList[index]),
          );
        },
      ),
    );
  }
}
