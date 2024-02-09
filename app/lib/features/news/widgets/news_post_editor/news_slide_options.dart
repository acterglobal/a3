import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/post_attachment_options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class NewsSlideOptions extends ConsumerStatefulWidget {
  const NewsSlideOptions({super.key});

  @override
  ConsumerState<NewsSlideOptions> createState() => _NewsSlideOptionsState();
}

class _NewsSlideOptionsState extends ConsumerState<NewsSlideOptions> {
  List<NewsSlideItem> newsSlideList = <NewsSlideItem>[];

  @override
  Widget build(BuildContext context) {
    newsSlideList = ref.watch(newsStateProvider).newsSlideList;
    return newsSlideOptionsUI(context);
  }

  Widget newsSlideOptionsUI(BuildContext context) {
    return Visibility(
      visible: ref.read(newsStateProvider).currentNewsSlide != null,
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: newsSlideListUI(context),
      ),
    );
  }

  Widget newsSlideListUI(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: newsSlideList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final slidePost = newsSlideList[index];
                return Stack(
                  fit: StackFit.passthrough,
                  children: [
                    InkWell(
                      onTap: () {
                        ref
                            .read(newsStateProvider.notifier)
                            .changeSelectedSlide(slidePost);
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 5.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.background,
                          borderRadius: BorderRadius.circular(5),
                          border:
                              ref.read(newsStateProvider).currentNewsSlide ==
                                      slidePost
                                  ? Border.all(color: Colors.white)
                                  : null,
                        ),
                        child: getIconAsPerSlideType(
                          slidePost.type,
                          slidePost.mediaFile,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(newsStateProvider.notifier)
                              .deleteSlide(index);
                        },
                        child: Icon(
                          Icons.remove_circle_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        IconButton(
          onPressed: () => showPostAttachmentOptions(context),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  void showPostAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (ctx) => PostAttachmentOptions(
        onTapAddText: () => NewsUtils.addTextSlide(ref),
        onTapImage: () async => await NewsUtils.addImageSlide(ref),
        onTapVideo: () async => await NewsUtils.addVideoSlide(ref),
      ),
    );
  }

  Widget getIconAsPerSlideType(
    NewsSlideType slidePostType,
    XFile? mediaFile,
  ) {
    switch (slidePostType) {
      case NewsSlideType.text:
        return const Icon(Atlas.size_text);
      case NewsSlideType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(5.0),
          child: Image(
            image: XFileImage(mediaFile!),
            fit: BoxFit.cover,
          ),
        );
      case NewsSlideType.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder(
              future: NewsUtils.getThumbnailData(mediaFile!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Image.file(
                      snapshot.data!,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Container(
              color: Colors.black38,
              child: const Icon(Icons.play_arrow_outlined, size: 32),
            ),
          ],
        );
      default:
        return Container();
    }
  }
}
