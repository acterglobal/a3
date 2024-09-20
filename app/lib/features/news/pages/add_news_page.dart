import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/news_slide_options.dart';
import 'package:acter/features/news/widgets/news_post_editor/select_action_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::news::add_page');

const addNewsKey = Key('add-news');

class AddNewsPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  const AddNewsPage({super.key = addNewsKey, this.initialSelectedSpace});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => AddNewsState();
}

class AddNewsState extends ConsumerState<AddNewsPage> {
  EditorState textEditorState = EditorState.blank();
  NewsSlideItem? selectedNewsPost;

  @override
  void initState() {
    super.initState();
    widget.initialSelectedSpace.let((p0) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(newsStateProvider.notifier).setSpaceId(p0);
      });
    });
    ref.listenManual(newsStateProvider, fireImmediately: true,
        (prevState, nextState) async {
      final isText = nextState.currentNewsSlide?.type == NewsSlideType.text;
      final changed = prevState?.currentNewsSlide != nextState.currentNewsSlide;
      if (isText && changed) {
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
  }

  //Build UI
  @override
  Widget build(BuildContext context) {
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
        onPressed: () {
          // Hide Keyboard
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          Navigator.pop(context);
        },
        icon: const Icon(Atlas.xmark_circle),
      ),
      backgroundColor: selectedNewsPost == null
          ? Colors.transparent
          : selectedNewsPost?.backgroundColor,
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
          onPressed: () => sendNews(context, ref),
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
          title: Text(L10n.of(context).addActionWidget),
          content: SelectActionItem(
            onShareEventSelected: () async {
              Navigator.pop(context);
              if (ref.read(newsStateProvider).newsPostSpaceId == null) {
                EasyLoading.showToast(L10n.of(context).pleaseFirstSelectASpace);
                return;
              }
              final notifier = ref.read(newsStateProvider.notifier);
              await notifier.selectEventToShare(context);
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
    return switch (selectedNewsPost?.type) {
      NewsSlideType.text => slideTextPostUI(context),
      NewsSlideType.image => slideImagePostUI(context),
      NewsSlideType.video => slideVideoPostUI(context),
      _ => emptySlidePostUI(context),
    };
  }

  //Show selected Action Buttons
  Widget selectedActionButtonsUI() {
    final newsReferences = selectedNewsPost?.newsReferencesModel;
    if (newsReferences == null) return const SizedBox();
    final calEventId = newsReferences.id;
    return Positioned(
      bottom: 10,
      left: 10,
      child: Row(
        children: [
          if (newsReferences.type == NewsReferencesType.calendarEvent &&
              calEventId != null)
            ref.watch(calendarEventProvider(calEventId)).when(
                  data: (calendarEvent) {
                    return SizedBox(
                      width: 300,
                      child: EventItem(
                        event: calendarEvent,
                        isShowRsvp: false,
                        onTapEventItem: (event) async {
                          await ref
                              .read(newsStateProvider.notifier)
                              .selectEventToShare(context);
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 300,
                    child: EventItemSkeleton(),
                  ),
                  error: (e, s) {
                    _log.severe('Failed to load cal event', e, s);
                    return Center(
                      child: Text(L10n.of(context).failedToLoadEvent(e)),
                    );
                  },
                ),
        ],
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
            semanticsLabel: L10n.of(context).state,
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          Text(
            L10n.of(context).createPostsAndEngageWithinSpace,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            key: NewsUpdateKeys.addTextSlide,
            onPressed: () => NewsUtils.addTextSlide(ref),
            child: Text(L10n.of(context).addTextSlide),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addImageSlide,
            onPressed: () async => await NewsUtils.addImageSlide(ref),
            child: Text(L10n.of(context).addImageSlide),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: NewsUpdateKeys.addVideoSlide,
            onPressed: () async => await NewsUtils.addVideoSlide(ref),
            child: Text(L10n.of(context).addVideoSlide),
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
                ref
                    .read(newsStateProvider.notifier)
                    .changeTextSlideValue(body, html);
              },
            ),
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
        key: Key('add-news-slide-video-${videoFile.name}'),
        videoFile: File(videoFile.path),
      ),
    );
  }
}
