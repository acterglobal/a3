import 'dart:io';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/select_action_item.dart';
import 'package:acter/features/news/widgets/news_post_editor/news_slide_options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

const addNewsKey = Key('add-news');

class AddNewsPage extends ConsumerStatefulWidget {
  const AddNewsPage({super.key = addNewsKey});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => AddNewsState();
}

class AddNewsState extends ConsumerState<AddNewsPage> {
  EditorState textEditorState = EditorState.blank();
  NewsSlideItem? selectedNewsPost;

  //Build UI
  @override
  Widget build(BuildContext context) {
    ref.listenManual(newsStateProvider, fireImmediately: true,
        (prevState, nextState) async {
      if (nextState.currentNewsSlide != null && // we have a new one
              nextState.currentNewsSlide?.type ==
                  NewsSlideType.text && // and it is a text type
              prevState?.currentNewsSlide !=
                  nextState.currentNewsSlide // and the slides have changed
          ) {
        final next = nextState.currentNewsSlide!;
        final document = next.html != null
            ? ActerDocumentHelpers.fromHtml(next.html!)
            : ActerDocumentHelpers.fromMarkdown(next.text ?? '');
        final autoFocus =
            (next.html?.isEmpty ?? true) && (next.text?.isEmpty ?? true);

        setState(() {
          selectedNewsPost = next;
          textEditorState = EditorState(document: document);
        });

        if (autoFocus) {
          WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
            // we have switched to an empty text slide: auto focus the editor
            textEditorState.updateSelectionWithReason(
              Selection.single(
                path: [0],
                startOffset: 0,
              ),
              reason: SelectionUpdateReason.uiEvent,
            );
          });
        }
      } else {
        setState(() => selectedNewsPost = nextState.currentNewsSlide);
      }
    });
    return Scaffold(
      appBar: appBarUI(context),
      body: bodyUI(context),
      floatingActionButton: actionButtonUI(context),
    );
  }

  //App Bar
  AppBar appBarUI(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Atlas.xmark_circle),
      ),
      backgroundColor: selectedNewsPost == null
          ? Colors.transparent
          : selectedNewsPost?.backgroundColor,
      actions: selectedNewsPost == null
          ? []
          : [
              IconButton(
                onPressed: () => selectActionItemDialog(context),
                icon: const Icon(Atlas.plus_circle),
              ),
              IconButton(
                key: NewsUpdateKeys.slideBackgroundColor,
                onPressed: () {
                  ref
                      .read(newsStateProvider.notifier)
                      .changeTextSlideBackgroundColor();
                },
                icon: const Icon(Atlas.color),
              ),
            ],
    );
  }

  //Action Button
  Widget actionButtonUI(BuildContext context) {
    return Visibility(
      visible: selectedNewsPost != null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          key: NewsUpdateKeys.newsSubmitBtn,
          onPressed: () => sendNews(context),
          child: const Icon(Icons.send),
        ),
      ),
    );
  }

  //Select any widget for action button
  void selectActionItemDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Add an action widget'),
          content: SelectActionItem(
            onSpaceItemSelected: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await ref
                  .read(newsStateProvider.notifier)
                  .changeInvitedSpaceId(context);
            },
            onChatItemSelected: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await ref
                  .read(newsStateProvider.notifier)
                  .changeInvitedChatId(context);
            },
          ),
        );
      },
    );
  }

  //Body UI
  Widget bodyUI(BuildContext context) {
    return Column(
      children: [
        //News content UI
        Expanded(child: newsContentUI()),
        //Slide options
        const NewsSlideOptions(),
      ],
    );
  }

  Widget newsContentUI() {
    return Stack(
      fit: StackFit.expand,
      children: [
        //Selected Slide Data View
        slidePostUI(context),
        //Selected Action Buttons View
        selectedActionButtonsUI(),
      ],
    );
  }

  //Show slide data view based on the current slide selection
  Widget slidePostUI(BuildContext context) {
    switch (selectedNewsPost?.type) {
      case NewsSlideType.text:
        return slideTextPostUI(context);
      case NewsSlideType.image:
        return slideImagePostUI(context);
      case NewsSlideType.video:
        return slideVideoPostUI(context);
      default:
        return emptySlidePostUI(context);
    }
  }

  //Show selected Action Buttons
  Widget selectedActionButtonsUI() {
    final invitedSpaceId = selectedNewsPost?.invitedSpaceId;
    final invitedChatId = selectedNewsPost?.invitedChatId;

    return Positioned(
      bottom: 10,
      left: 10,
      child: Row(
        children: [
          if (invitedSpaceId != null)
            InkWell(
              onTap: () async {
                await ref
                    .read(newsStateProvider.notifier)
                    .changeInvitedSpaceId(context);
              },
              child: Column(
                children: [
                  const Text('Space'),
                  SpaceChip(spaceId: invitedSpaceId),
                ],
              ),
            ),
          if (invitedSpaceId != null) const SizedBox(width: 10.0),
          if (invitedChatId != null)
            InkWell(
              onTap: () async {
                await ref
                    .read(newsStateProvider.notifier)
                    .changeInvitedChatId(context);
              },
              child: Column(
                children: [
                  const Text('Chat'),
                  chatChip(invitedChatId),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget chatChip(String invitedChatId) {
    return Chip(
      avatar: RoomAvatar(
        roomId: invitedChatId,
        avatarSize: 30,
        showParent: true,
      ),
      label: ref.watch(chatProfileDataProviderById(invitedChatId)).when(
            data: (profile) => Text(
              profile.displayName ?? invitedChatId,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
            error: (err, stackTrace) {
              return Text(
                invitedChatId,
                overflow: TextOverflow.clip,
              );
            },
            loading: () => const CircularProgressIndicator(),
          ),
    );
  }

  Widget emptySlidePostUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset(
            'assets/images/empty_updates.svg',
            semanticsLabel: 'state',
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          Text(
            'Create actionable posts and engage everyone within your space.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            key: NewsUpdateKeys.addTextSlide,
            onPressed: () => NewsUtils.addTextSlide(ref),
            child: const Text('Add text slide'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addImageSlide,
            onPressed: () async => await NewsUtils.addImageSlide(ref),
            child: const Text('Add image slide'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addVideoSlide,
            onPressed: () async => await NewsUtils.addVideoSlide(ref),
            child: const Text('Add video slide'),
          ),
        ],
      ),
    );
  }

  Widget slideTextPostUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      color: selectedNewsPost?.backgroundColor,
      child: SingleChildScrollView(
        child: IntrinsicHeight(
          child: HtmlEditor(
            key: NewsUpdateKeys.textSlideInputField,
            editorState: textEditorState,
            editable: true,
            autoFocus: false,
            // we manage the auto focus manually
            shrinkWrap: true,
            onChanged: (body, html) {
              ref
                  .read(newsStateProvider.notifier)
                  .changeTextSlideValue(body, html);
            },
          ),
        ),
      ),
    );
  }

  Widget slideImagePostUI(BuildContext context) {
    final imageFile = selectedNewsPost!.mediaFile;
    return Container(
      alignment: Alignment.center,
      color: selectedNewsPost!.backgroundColor,
      child: Image.file(
        File(imageFile!.path),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget slideVideoPostUI(BuildContext context) {
    final videoFile = selectedNewsPost!.mediaFile!;
    return Container(
      alignment: Alignment.center,
      color: selectedNewsPost!.backgroundColor,
      child: ActerVideoPlayer(
        key: Key(videoFile.name),
        videoFile: File(videoFile.path),
      ),
    );
  }

  Future<void> sendNews(BuildContext context) async {
    final client = ref.read(alwaysClientProvider);
    final spaceId = ref.read(newsStateProvider).newsPostSpaceId;
    final newsSlideList = ref.watch(newsStateProvider).newsSlideList;

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
        // If slide type is text
        if (slidePost.type == NewsSlideType.text) {
          if (slidePost.text == null || slidePost.text!.trim().isEmpty) {
            EasyLoading.showError('Your text slides must contains some text');
            return;
          }
          final textDraft = slidePost.html != null
              ? client.textHtmlDraft(slidePost.html!, slidePost.text!)
              : client.textMarkdownDraft(slidePost.text!);
          final textSlideDraft = textDraft.intoNewsSlideDraft();

          textSlideDraft.color(
            sdk.api.newColorizeBuilder(
              null,
              slidePost.backgroundColor?.value,
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
              slidePost.backgroundColor?.value,
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
              slidePost.backgroundColor?.value,
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
      context.goNamed(Routes.main.name); // go to the home / main updates
    } catch (err) {
      EasyLoading.showError('$displayMsg failed: \n $err');
    }
  }
}
