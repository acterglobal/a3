import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/html_editor/html_editor.dart';
import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/news_slide_options.dart';
import 'package:acter/features/news/widgets/news_post_editor/select_action_item.dart';
import 'package:acter/features/news/widgets/news_post_editor/selected_action_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

const addNewsKey = Key('add-news');

class AddNewsPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const AddNewsPage({
    super.key = addNewsKey,
    this.initialSelectedSpace,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => AddNewsState();
}

class AddNewsState extends ConsumerState<AddNewsPage> {
  EditorState textEditorState = EditorState.blank();
  NewsSlideItem? selectedNewsPost;

  @override
  void initState() {
    super.initState();
    widget.initialSelectedSpace.map((initialSpaceId) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(newsStateProvider.notifier).setSpaceId(initialSpaceId);
      });
    });
    ref.listenManual(newsStateProvider, fireImmediately: true,
        (prevState, nextState) async {
      final nextSlide = nextState.currentNewsSlide;
      final isText = nextSlide != null && nextSlide.type == NewsSlideType.text;
      final changed = prevState?.currentNewsSlide != nextSlide;
      if (isText && changed) {
        final document = ActerDocumentHelpers.parse(
          nextSlide.text ?? '',
          htmlContent: nextSlide.html,
        );

        final autoFocus = nextSlide.html?.isEmpty != false &&
            nextSlide.text?.isEmpty != false;

        setState(() {
          selectedNewsPost = nextSlide;
          if (!document.isEmpty) {
            textEditorState = EditorState(document: document);
          }
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
  }

  //Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarUI(context),
      body: bodyUI(context),
      floatingActionButton:
          selectedNewsPost != null ? actionButtonUI(context) : null,
    );
  }

  Future<bool> canClear() async {
    if (ref.read(newsStateProvider.notifier).isEmpty()) {
      return true;
    }

    // we first need to confirm with the user that we can clear everything.
    final bool? confirm = await showAdaptiveDialog<bool>(
      context: context,
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: 'confirmCanClear'),
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context).deleteNewsDraftTitle),
          content: Text(
            L10n.of(context).deleteNewsDraftText,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            OutlinedButton(
              key: NewsUpdateKeys.cancelClose,
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                L10n.of(context).no,
              ),
            ),
            ActerDangerActionButton(
              key: NewsUpdateKeys.confirmDeleteDraft,
              onPressed: () async {
                Navigator.pop(context, true);
              },
              child: Text(
                L10n.of(context).deleteDraftBtn,
              ),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      ref.read(newsStateProvider.notifier).clear();
    }
    return confirm == true;
  }

  //App Bar
  AppBar appBarUI(BuildContext context) {
    return AppBar(
      leading: IconButton(
        key: NewsUpdateKeys.closeEditor,
        onPressed: () async {
          // Hide Keyboard
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          if (await canClear()) {
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          }
        },
        icon: const Icon(Atlas.xmark_circle),
      ),
      backgroundColor: selectedNewsPost?.backgroundColor ?? Colors.transparent,
      actions: selectedNewsPost == null
          ? []
          : [
              OutlinedButton.icon(
                onPressed: () => selectActionItemDialog(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(L10n.of(context).action),
              ),
              IconButton(
                key: NewsUpdateKeys.slideBackgroundColor,
                onPressed: () {
                  final notifier = ref.read(newsStateProvider.notifier);
                  notifier.changeTextSlideBackgroundColor();
                },
                icon: const Icon(Atlas.color),
              ),
            ],
    );
  }

  //Action Button
  Widget actionButtonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton(
        key: NewsUpdateKeys.newsSubmitBtn,
        onPressed: () => sendNews(context, ref),
        child: const Icon(Icons.send),
      ),
    );
  }

  //Select any widget for action button
  void selectActionItemDialog(BuildContext buildContext) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        final lang = L10n.of(context);
        return AlertDialog.adaptive(
          title: Text(lang.addActionWidget),
          content: SelectActionItem(
            onShareEventSelected: () async {
              Navigator.pop(context);
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.selectEventToShare(buildContext);
            },
            onSharePinSelected: () async {
              Navigator.pop(context);
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.selectPinToShare(buildContext);
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
        Positioned(
          bottom: 10,
          left: 10,
          child: SelectedActionButton(
            newsReferences: selectedNewsPost?.newsReferencesModel,
          ),
        ),
      ],
    );
  }

  //Show slide data view based on the current slide selection
  Widget slidePostUI(BuildContext context) {
    return selectedNewsPost.map(
          (slide) => switch (slide.type) {
            NewsSlideType.text => slideTextPostUI(context),
            NewsSlideType.image => slideImagePostUI(context, slide),
            NewsSlideType.video => slideVideoPostUI(context, slide),
          },
        ) ??
        emptySlidePostUI(context);
  }

  Widget emptySlidePostUI(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset(
            'assets/images/empty_updates.svg',
            semanticsLabel: lang.state,
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          Text(
            lang.createPostsAndEngageWithinSpace,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            key: NewsUpdateKeys.addTextSlide,
            onPressed: () => NewsUtils.addTextSlide(ref),
            child: Text(lang.addTextSlide),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addImageSlide,
            onPressed: () async => await NewsUtils.addImageSlide(ref),
            child: Text(lang.addImageSlide),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addVideoSlide,
            onPressed: () async => await NewsUtils.addVideoSlide(ref),
            child: Text(lang.addVideoSlide),
          ),
        ],
      ),
    );
  }

  Widget slideTextPostUI(BuildContext context) {
    return GestureDetector(
      onTap: () => SystemChannels.textInput.invokeMethod('TextInput.hide'),
      child: Container(
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
                final notifier = ref.read(newsStateProvider.notifier);
                notifier.changeTextSlideValue(body, html);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget slideImagePostUI(BuildContext context, NewsSlideItem slide) {
    final imageFile = slide.mediaFile;
    if (imageFile == null) throw 'media file of image slide not available';
    return Container(
      alignment: Alignment.center,
      color: slide.backgroundColor,
      child: Image.file(
        File(imageFile.path),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget slideVideoPostUI(BuildContext context, NewsSlideItem slide) {
    final videoFile = slide.mediaFile;
    if (videoFile == null) throw 'media file of video slide not available';
    return Container(
      alignment: Alignment.center,
      color: slide.backgroundColor,
      child: ActerVideoPlayer(
        key: Key('add-news-slide-video-${videoFile.name}'),
        videoFile: File(videoFile.path),
      ),
    );
  }
}
