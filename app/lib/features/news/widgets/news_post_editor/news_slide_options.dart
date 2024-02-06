import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/post_attachment_options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
    final newsPostSpaceId = ref.watch(newsStateProvider).newsPostSpaceId;
    return Visibility(
      visible: ref.read(newsStateProvider).currentNewsSlide != null,
      child: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (newsPostSpaceId != null)
              InkWell(
                key: NewsUpdateKeys.selectSpace,
                onTap: () async {
                  await ref
                      .read(newsStateProvider.notifier)
                      .changeNewsPostSpaceId(context);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Space',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SpaceChip(spaceId: newsPostSpaceId),
                  ],
                ),
              )
            else
              OutlinedButton(
                key: NewsUpdateKeys.selectSpace,
                onPressed: () async {
                  await ref
                      .read(newsStateProvider.notifier)
                      .changeNewsPostSpaceId(context);
                },
                child: const Text('Select Space'),
              ),
            verticalDivider(context),
            Expanded(child: newsSlideListUI(context)),
            IconButton(
              key: NewsUpdateKeys.newsSubmitBtn,
              onPressed: () => sendNews(context),
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                  Theme.of(context).colorScheme.background,
                ),
              ),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
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
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(
              Theme.of(context).colorScheme.background,
            ),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
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
        return FutureBuilder(
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
        );
      default:
        return Container();
    }
  }

  Future<void> sendNews(BuildContext context) async {
    final client = ref.read(alwaysClientProvider);
    final spaceId = ref.read(newsStateProvider).newsPostSpaceId;

    if (spaceId == null) {
      customMsgSnackbar(context, 'Please first select a space');
      return;
    }

    String displayMsg = 'Slide posting';
    // Show loading message
    EasyLoading.show(status: displayMsg);
    try {
      final space = await ref.read(spaceProvider(spaceId).future);
      NewsEntryDraft draft = space.newsDraft();
      for (final slidePost in newsSlideList) {
        final sdk = await ref.read(sdkProvider.future);
        String slideBgColor =
            'rgb(${slidePost.backgroundColor?.red}, ${slidePost.backgroundColor?.green}, ${slidePost.backgroundColor?.blue})';

        // If slide type is text
        if (slidePost.type == NewsSlideType.text && slidePost.text != null) {
          if (slidePost.text!.isEmpty) {
            EasyLoading.showError('Please add some text');
            return;
          }

          final textDraft = client.textMarkdownDraft(slidePost.text!);
          final textSlideDraft = textDraft.intoNewsSlideDraft();

          textSlideDraft.color(
            sdk.api.newColorizeBuilder(
              null,
              slideBgColor,
            ),
          );
          await draft.addSlide(textSlideDraft);
        }

        // If slide type is image
        else if (slidePost.type == NewsSlideType.image &&
            slidePost.mediaFile != null) {
          final file = slidePost.mediaFile!;
          String? mimeType = file.mimeType ?? lookupMimeType(file.path);
          if (mimeType == null) {
            EasyLoading.showError('Invalid media format');
            return;
          }
          if (!mimeType.startsWith('image/')) {
            EasyLoading.showError(
              'Posting of $mimeType not yet supported',
            );
            return;
          }
          Uint8List bytes = await file.readAsBytes();
          final decodedImage = await decodeImageFromList(bytes);
          final imageDraft = client
              .imageDraft(file.path, mimeType)
              .size(bytes.length)
              .width(decodedImage.width)
              .height(decodedImage.height);
          final imageSlideDraft = imageDraft.intoNewsSlideDraft();
          imageSlideDraft.color(
            sdk.api.newColorizeBuilder(
              null,
              slideBgColor,
            ),
          );
          await draft.addSlide(imageSlideDraft);
        }

        // If slide type is video
        else if (slidePost.type == NewsSlideType.video &&
            slidePost.mediaFile != null) {
          final file = slidePost.mediaFile!;
          String? mimeType = file.mimeType ?? lookupMimeType(file.path);
          if (mimeType == null) {
            EasyLoading.showError('Invalid media format');
            return;
          }
          if (!mimeType.startsWith('video/')) {
            EasyLoading.showError(
              'Posting of $mimeType not yet supported',
            );
            return;
          }
          Uint8List bytes = await file.readAsBytes();
          final videoDraft =
              client.videoDraft(file.path, mimeType).size(bytes.length);
          final videoSlideDraft = videoDraft.intoNewsSlideDraft();
          videoSlideDraft.color(
            sdk.api.newColorizeBuilder(
              null,
              slideBgColor,
            ),
          );
          await draft.addSlide(videoSlideDraft);
        }
      }
      await draft.send();

      // close loading
      EasyLoading.dismiss();

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      // FIXME due to #718. well lets at least try forcing a refresh upon route.
      ref.invalidate(newsListProvider);
      ref.invalidate(newsStateProvider);
      // Navigate back to update screen.
      Navigator.of(context).pop();
    } catch (err) {
      EasyLoading.showError('$displayMsg failed: \n $err');
    }
  }
}
