import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/post_attachment_options.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    return Visibility(
      visible: ref.watch(newsStateProvider).currentNewsSlide != null &&
          !(keyboardVisibility.value ?? false),
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: newsSlideListUI(context),
      ),
    );
  }

  Widget newsSlideListUI(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        parentSpaceSelector(),
        verticalDivider(context),
        Expanded(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
                      key: Key('slide-${slidePost.type.name}-$index'),
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
                          border: ref
                                      .watch(newsStateProvider)
                                      .currentNewsSlide ==
                                  slidePost
                              ? Border.all(
                                  color:
                                      Theme.of(context).colorScheme.textColor,
                                )
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
                        key: Key('remove-slide-${slidePost.type.name}-$index'),
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
          key: NewsUpdateKeys.addNewsSlide,
          onPressed: () => showPostAttachmentOptions(context),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget parentSpaceSelector() {
    final newsPostSpaceId = ref.watch(newsStateProvider).newsPostSpaceId;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: (newsPostSpaceId != null)
          ? InkWell(
              key: NewsUpdateKeys.selectSpace,
              onTap: () async {
                await ref
                    .read(newsStateProvider.notifier)
                    .changeNewsPostSpaceId(context);
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  RoomAvatarBuilder(
                    roomId: newsPostSpaceId,
                    displayMode: DisplayMode.Space,
                    avatarSize: 42,
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const Icon(
                        Atlas.pencil_box,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              key: NewsUpdateKeys.selectSpace,
              onPressed: () async {
                await ref
                    .read(newsStateProvider.notifier)
                    .changeNewsPostSpaceId(context);
              },
              child: Text(L10n.of(context).selectSpace),
            ),
    );
  }

  Widget verticalDivider(BuildContext context) {
    return Container(
      height: 50,
      width: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      color: Theme.of(context).colorScheme.onPrimary,
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
