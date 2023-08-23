import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsWidget extends ConsumerStatefulWidget {
  const NewsWidget({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends ConsumerState<NewsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider)!;
    final newsList = ref.watch(newsListProvider);
    return newsList.when(
      data: (data) {
        return PageView.builder(
          itemCount: data.length,
          onPageChanged: (int page) {},
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) => InkWell(
            onDoubleTap: () {
              LikeAnimation.run(index);
            },
            child: NewsItem(
              client: client,
              news: data[index],
              index: index,
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
