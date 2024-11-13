import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item/news_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsFullView extends ConsumerStatefulWidget {
  final List<NewsEntry> newsList;
  final int initialPageIndex;

  const NewsFullView({
    super.key,
    required this.newsList,
    this.initialPageIndex = 0,
  });

  @override
  ConsumerState<NewsFullView> createState() => NewsVerticalViewState();
}

class NewsVerticalViewState extends ConsumerState<NewsFullView> {
  static PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPageIndex);
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
        },
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.newsList.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) => InkWell(
          onDoubleTap: () async {
            LikeAnimation.run(index);
            final news = widget.newsList[index];
            final manager = await ref.read(newsReactionsProvider(news).future);
            final status = manager.likedByMe();
            if (!status) {
              await manager.sendLike();
            }
          },
          child: NewsItem(news: widget.newsList[index]),
        ),
      ),
    );
  }
}
