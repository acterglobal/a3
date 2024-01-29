import 'dart:math';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
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

class SlideEditorOptions extends ConsumerStatefulWidget {
  const SlideEditorOptions({super.key});

  @override
  ConsumerState<SlideEditorOptions> createState() => _SlideEditorOptionsState();
}

class _SlideEditorOptionsState extends ConsumerState<SlideEditorOptions> {
  List<NewsSlideItem> newsPostList = <NewsSlideItem>[];

  @override
  Widget build(BuildContext context) {
    newsPostList = ref.watch(newSlideListProvider).getNewsList();
    return slideEditorOptions(context);
  }

  Widget slideEditorOptions(BuildContext context) {
    final slideEditorBackgroundColor = Theme.of(context).colorScheme.primary;

    return Visibility(
      visible: ref.watch(currentNewsSlideProvider) != null,
      child: Container(
        color: slideEditorBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SelectSpaceFormField(
              canCheck: 'CanPostNews',
              emptyText: 'Space',
            ),
            verticalDivider(context),
            Expanded(
              child: slidePostLists(context),
            ),
            IconButton(
              onPressed: () => sendUpdates(context),
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
      color: Theme.of(context).colorScheme.background,
    );
  }

  Widget slidePostLists(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: newsPostList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final slidePost = newsPostList[index];
                return InkWell(
                  onTap: () {
                    ref.watch(currentNewsSlideProvider.notifier).state =
                        slidePost;
                    setState(() {});
                  },
                  onLongPress: () {
                    ref.watch(newSlideListProvider).deleteSlide(index);
                    setState(() {});
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
                    ),
                    child: getIconAsPerSlideType(
                      slidePost.type,
                      slidePost.mediaFile,
                    ),
                  ),
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
        onTapAddText: () => addTextSlide(),
        onTapImage: () async => await addImageSlide(),
        onTapVideo: () async => await addVideoSlide(),
      ),
    );
  }

  //Add text slide
  void addTextSlide() {
    NewsSlideItem textSlide = NewsSlideItem(
      type: NewsSlideType.text,
      text: '',
      textBackgroundColor: Colors.primaries[Random().nextInt(Colors.primaries.length)],
    );
    ref.watch(newSlideListProvider).addSlide(textSlide);
  }

  //Add image slide
  Future<void> addImageSlide() async {
    XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.image,
              mediaFile: imageFile,
            ),
          );
    }
  }

  //Add video slide
  Future<void> addVideoSlide() async {
    XFile? videoFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);

    if (videoFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.video,
              mediaFile: videoFile,
            ),
          );
    }
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

  Future<void> sendUpdates(BuildContext context) async {
    final client = ref.read(clientProvider)!;
    final spaceId = ref.read(selectedSpaceIdProvider);

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
      for (final slidePost in newsPostList) {
        // If slide type is text
        if (slidePost.type == NewsSlideType.text && slidePost.text != null) {
          final textDraft = client.textMarkdownDraft(slidePost.text!);
          await draft.addSlide(textDraft);
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
          await draft.addSlide(imageDraft);
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
          await draft.addSlide(videoDraft);
        }
      }
      draft.swapSlides(0, newsPostList.length - 1);
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
      // Navigate back to update screen.
      Navigator.of(context).pop();
    } catch (err) {
      EasyLoading.showError('$displayMsg failed: \n $err');
    }
  }
}
