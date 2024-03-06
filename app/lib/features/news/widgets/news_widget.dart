import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final client = ref.watch(alwaysClientProvider);
    final newsList = ref.watch(newsListProvider);
    return newsList.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: EmptyState(
              title: 'You have no updates',
              subtitle:
                  'Create actionable posts and engage everyone within your space.',
              image: 'assets/images/empty_updates.svg',
              primaryButton: ElevatedButton(
                onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
                child: const Text('Create New update'),
              ),
            ),
          );
        }
        return PageView.builder(
          controller: _pageController,
          itemCount: data.length,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) => InkWell(
            onDoubleTap: () async {
              LikeAnimation.run(index);
              final news = data[index];
              final manager =
                  await ref.read(newsReactionsProvider(news).future);
              final status = manager.likedByMe();
              if (!status) {
                await manager.sendLike();
              }
            },
            child: NewsItem(
              client: client,
              news: data[index],
              index: index,
              pageController: _pageController,
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return const Center(child: Text("Couldn't fetch news"));
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
