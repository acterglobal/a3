import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item/news_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::news_widget');

class NewsWidget extends ConsumerStatefulWidget {
  const NewsWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends ConsumerState<NewsWidget> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsListLoader = ref.watch(newsListProvider(null));
    return newsListLoader.when(
      data: (newsList) {
        if (newsList.isEmpty) {
          return Center(
            child: EmptyState(
              title: L10n.of(context).youHaveNoUpdates,
              subtitle: L10n.of(context).createPostsAndEngageWithinSpace,
              image: 'assets/images/empty_updates.svg',
              primaryButton: ActerPrimaryActionButton(
                onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
                child: Text(L10n.of(context).createNewUpdate),
              ),
            ),
          );
        }
        return PageView.builder(
          controller: _pageController,
          itemCount: newsList.length,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) => InkWell(
            onDoubleTap: () async {
              LikeAnimation.run(index);
              final news = newsList[index];
              final manager =
                  await ref.read(newsReactionsProvider(news).future);
              final status = manager.likedByMe();
              if (!status) {
                await manager.sendLike();
              }
            },
            child: NewsItem(news: newsList[index]),
          ),
        );
      },
      error: (e, s) {
        _log.severe('Failed to load news list', e, s);
        return Center(
          child: Text(L10n.of(context).couldNotFetchNews),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
