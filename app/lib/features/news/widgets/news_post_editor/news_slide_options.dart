import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/widgets/room/room_avatar_builder.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/post_attachment_options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final curSlide = ref.watch(newsStateProvider).currentNewsSlide;
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    return Visibility(
      visible: curSlide != null && keyboardVisibility.value != true,
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        child: newsSlideListUI(context),
      ),
    );
  }

  Widget newsSlideListUI(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentSlide = ref.watch(newsStateProvider).currentNewsSlide;
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
                        final notifier = ref.read(newsStateProvider.notifier);
                        notifier.changeSelectedSlide(slidePost);
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(5),
                          border: currentSlide == slidePost
                              ? Border.all(color: colorScheme.textColor)
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
                          final notifier = ref.read(newsStateProvider.notifier);
                          notifier.deleteSlide(index);
                        },
                        child: Icon(
                          Icons.remove_circle_outlined,
                          color: colorScheme.error,
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
          icon: Icon(PhosphorIcons.stackPlus()),
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
                final notifier = ref.read(newsStateProvider.notifier);
                await notifier.changeNewsPostSpaceId(context);
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  RoomAvatarBuilder(
                    roomId: newsPostSpaceId,
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
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: Theme.of(context).colorScheme.onSurface),
              ),
              onPressed: () async {
                final notifier = ref.read(newsStateProvider.notifier);
                await notifier.changeNewsPostSpaceId(context);
              },
              child: Text(
                L10n.of(context).selectSpace,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
    );
  }

  Widget verticalDivider(BuildContext context) {
    return Container(
      height: 50,
      width: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
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
      builder: (context) => PostAttachmentOptions(
        onTapAddText: () => NewsUtils.addTextSlide(ref: ref),
        onTapImage: () async => await NewsUtils.addImageSlide(ref: ref),
        onTapVideo: () async => await NewsUtils.addVideoSlide(ref: ref),
      ),
    );
  }

  Widget getIconAsPerSlideType(NewsSlideType slidePostType, XFile? mediaFile) {
    return switch (slidePostType) {
      NewsSlideType.text => const Icon(Atlas.size_text),
      NewsSlideType.image => ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image(
            image: XFileImage(mediaFile.expect('image slide needs media file')),
            fit: BoxFit.cover,
          ),
        ),
      NewsSlideType.video => Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder(
              future: NewsUtils.getThumbnailData(
                mediaFile.expect('video slide needs media file'),
              ),
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.file(
                      data,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Container(
              color: Colors.black38,
              child: const Icon(
                Icons.play_arrow_outlined,
                size: 32,
              ),
            ),
          ],
        ),
    };
  }
}
