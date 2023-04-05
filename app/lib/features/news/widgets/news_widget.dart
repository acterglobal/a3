import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/common/controllers/client_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/features/news/controllers/news_controller.dart';
import 'package:acter/features/news/widgets/news_item.dart';
import 'package:acter/features/news/widgets/stream_types_selection.dart';
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
    final newsList = ref.watch(newsListProvider);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MediaQuery.of(context).size.width < 600
            ? const UserAvatarWidget()
            : const SizedBox.shrink(),
        centerTitle: true,
        title: const StreamTypesSelection(),
      ),
      body: newsList.when(
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
                client: ref.read(clientProvider)!,
                news: data[index],
                index: index,
              ),
            ),
          );
        },
        error: (error, stackTrace) =>
            const Center(child: Text('Couldn\'t fetch news')),
        loading: () => const Center(
          child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
