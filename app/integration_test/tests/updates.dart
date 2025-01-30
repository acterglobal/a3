import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/pages/add_news/add_news_page.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/space/dialogs/leave_space.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';

extension ActerNews on ConvenientTest {
  Future<void> openCreateNews() async {
    await navigateTo([
      Keys.mainNav,
      MainNavKeys.quickJump,
      MainNavKeys.quickJump,
      QuickJumpKeys.createUpdateAction,
    ]);
  }

  Future<EditorState> _getNewsTextEditorState() async {
    final addNewsFinder = find.byKey(addNewsKey);
    await addNewsFinder.should(findsOneWidget);
    return (tester.firstState(addNewsFinder) as AddNewsState).textEditorState;
  }

  Future<void> toggleBackgroundColor() async {
    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    await slideBackgroundColorKey.tap();
  }

  Future<EditorState> addTextSlide(String text) async {
    final addTextSlideKey = find.byKey(NewsUpdateKeys.addTextSlide);
    await addTextSlideKey.should(findsOneWidget);
    await addTextSlideKey.tap();
    final editorState = await _getNewsTextEditorState();
    assert(editorState.editable, 'Not editable');
    assert(editorState.selection != null, 'No selection');
    await editorState.insertTextAtPosition(text);
    return editorState;
  }

  Future<void> submitNews(String? spaceId) async {
    if (spaceId != null) {
      await selectSpace(spaceId, NewsUpdateKeys.selectSpace);
    }

    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<void> addImageSlide({String? filepath}) async {
    final addImageSlideKey = find.byKey(NewsUpdateKeys.addImageSlide);
    await addImageSlideKey.should(findsOneWidget);

    // Adding Image Slide Object into Slide List
    final context = tester.element(addImageSlideKey);
    final ref = ProviderScope.containerOf(context);
    final imageFile = await convertAssetImageToXFile(
      filepath ?? 'assets/images/update_onboard.png',
    );
    final slide = NewsSlideItem(
      type: NewsSlideType.image,
      mediaFile: imageFile,
    );
    ref.read(newsStateProvider.notifier).addSlide(slide);
  }

  Future<void> addVideoSlide({String? filepath}) async {
    final addVideoSlideKey = find.byKey(NewsUpdateKeys.addVideoSlide);
    await addVideoSlideKey.should(findsOneWidget);

    // Adding Video Slide Object into Slide List
    final context = tester.element(addVideoSlideKey);
    final ref = ProviderScope.containerOf(context);
    final videoFile =
        await convertAssetImageToXFile(filepath ?? 'assets/videos/video.mp4');
    final slide = NewsSlideItem(
      type: NewsSlideType.video,
      mediaFile: videoFile,
    );
    ref.read(newsStateProvider.notifier).addSlide(slide);
  }

  Future<void> openAddSlide() async {
    // Open bottom sheet for adding more slide
    final addMoreNewsKey = find.byKey(NewsUpdateKeys.addNewsSlide);
    await addMoreNewsKey.should(findsOneWidget);
    await addMoreNewsKey.tap();
  }

  Future<void> closeAddSlide() async {
    // Close bottom sheet
    final cancelKey = find.byKey(NewsUpdateKeys.cancelButton);
    await cancelKey.should(findsOneWidget);
    await cancelKey.tap();
  }
}

void updateTests() {
  acterTestWidget('Single Plain-Text News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    const text = 'Welcome to the show';

    await t.openCreateNews();
    await t.addTextSlide(text);
    await t.toggleBackgroundColor();
    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final textUpdateContent = find.byKey(NewsUpdateKeys.textUpdateContent);
    await textUpdateContent.should(findsOneWidget);
    await find.text(text).should(findsWidgets);
  });

  acterTestWidget('Multi-Slide Html-Text News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    const text = 'This is our big update';

    await t.openCreateNews();
    final editorState = await t.addTextSlide(text);

    await editorState.insertNewLine();
    await editorState.insertTextAtCurrentSelection(
      'This is a second line of text with some ',
    );
    final lastSelectable = editorState.getLastSelectable()!;
    final transaction = editorState.transaction;
    transaction.insertText(
      lastSelectable.$1,
      40,
      'bold text',
      attributes: {'bold': true},
    );
    await editorState.apply(transaction);

    await t.openAddSlide();
    await t.addTextSlide('this is slide b');

    // ensure the editor has properly reset
    await find.text(text).should(findsNothing);

    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final textUpdateContent = find.byKey(NewsUpdateKeys.textUpdateContent);
    await textUpdateContent.should(findsOneWidget);
    await find.text(text).should(findsOneWidget);
    await find
        .text('This is a second line of text with some bold text')
        .should(findsOneWidget);
    // FIXME: actually check the `bold text` is bold.... how to do that?
  });

  acterTestWidget('Single Image News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();

    await t.openCreateNews();
    await t.addImageSlide();
    await t.toggleBackgroundColor();
    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);
  });

  acterTestWidget('Leaving space removes Image News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();

    await t.openCreateNews();
    await t.addImageSlide();
    await t.toggleBackgroundColor();
    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);
    await t.gotoSpace(spaceId);
    await t.navigateTo([
      SpaceToolbar.optionsMenu,
      SpaceToolbar.leaveMenu,
      leaveSpaceYesBtn, // leaving the space
    ]);
    await t.navigateTo([MainNavKeys.updates]);
    // news are gone
    await imageUpdateContent.should(findsNothing);
  });

  acterTestWidget('Single Video News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();

    await t.openCreateNews();
    await t.addVideoSlide();
    await t.toggleBackgroundColor();
    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final videoUpdateContent = find.byKey(NewsUpdateKeys.videoNewsContent);
    await videoUpdateContent.should(findsOneWidget);
  });

  acterTestWidget('Multi-Slide News Updates', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    const text = 'Welcome to the show';

    await t.openCreateNews();
    await t.addTextSlide('');
    await t.toggleBackgroundColor();

    await t.openAddSlide();
    await t.addImageSlide();
    await t.closeAddSlide();
    await t.toggleBackgroundColor();

    await t.openAddSlide();
    await t.addVideoSlide();
    await t.closeAddSlide();
    await t.toggleBackgroundColor();

    await t.submitNews(null); // no space selected, this will fail
    // so we select a space
    await t.selectSpace(spaceId, NewsUpdateKeys.selectSpace);
    await t.submitNews(null); // text is empty, so this will fail

    await t.trigger(
      const Key('remove-slide-text-0'),
    ); // will remove the empty slide

    // Getting image slide in list
    await t.trigger(const Key('slide-image-0'));
    await t.toggleBackgroundColor();

    // Getting video slide in list
    await t.trigger(const Key('slide-video-1'));

    await t.toggleBackgroundColor();
    await t.openAddSlide();
    await t.addTextSlide(text); //add a slide with content

    await t.toggleBackgroundColor();
    await t.submitNews(null); // this will now work

    // we expect to be thrown to the news screen and see our latest item first:
    // For Image
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);
  });

  acterTestWidget('Remove Single Image News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();

    await t.openCreateNews();
    await t.addImageSlide();
    await t.toggleBackgroundColor();
    await t.submitNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);

    // open news sidebar bottom sheet for action buttons
    await t.trigger(NewsUpdateKeys.newsSidebarActionBottomSheet);

    // click on remove button for show confirm dialog
    await t.trigger(NewsUpdateKeys.newsSidebarActionRemoveBtn);

    // click on remove button
    await t.trigger(NewsUpdateKeys.removeButton);
  });
}
