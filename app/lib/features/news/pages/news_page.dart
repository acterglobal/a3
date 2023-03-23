import 'package:acter/common/animations/like_animation.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/features/news/controllers/news_controller.dart';
import 'package:acter/features/news/widgets/news_item.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StreamTypes { news, stories }

class StreamTypesSelection extends StatefulWidget {
  const StreamTypesSelection({super.key});

  @override
  State<StreamTypesSelection> createState() => _StreamTypesSelectionState();
}

class _StreamTypesSelectionState extends State<StreamTypesSelection> {
  Set<StreamTypes> selection = <StreamTypes>{
    StreamTypes.news,
  };

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StreamTypes>(
      segments: const <ButtonSegment<StreamTypes>>[
        ButtonSegment<StreamTypes>(
            value: StreamTypes.news, icon: Icon(Atlas.newspaper_thin),),
        ButtonSegment<StreamTypes>(
            value: StreamTypes.stories, icon: Icon(Atlas.image_message_thin),),
      ],
      selected: selection,
      onSelectionChanged: (Set<StreamTypes> newSelection) {
        setState(() {
          selection = newSelection;
        });
      },
      multiSelectionEnabled: true,
    );
  }
}

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage>
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
                client: ref.read(homeStateProvider)!,
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
