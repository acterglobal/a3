import 'dart:io';

import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import '../support/setup.dart';
import '../support/spaces.dart';

extension ActerNews on ConvenientTest {
  Future<void> createTextNews(String spaceId, String text) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final updatesKey = find.byKey(MainNavKeys.updates);
    await updatesKey.should(findsOneWidget);
    await updatesKey.tap();

    final newsCreateUpdatesKey = find.byKey(NewsUpdateKeys.addNewsUpdate);
    await newsCreateUpdatesKey.should(findsOneWidget);
    await newsCreateUpdatesKey.tap();

    final addTextSlideKey = find.byKey(NewsUpdateKeys.addTextSlide);
    await addTextSlideKey.should(findsOneWidget);
    await addTextSlideKey.tap();

    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    final updateSlideTextField = find.byKey(NewsUpdateKeys.textSlideInputField);
    await updateSlideTextField.should(findsOneWidget);
    await updateSlideTextField.enterTextWithoutReplace(text);

    await slideBackgroundColorKey.tap();

    await selectSpace(spaceId, NewsUpdateKeys.selectSpace);

    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<void> createImageNews(String spaceId) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final updatesKey = find.byKey(MainNavKeys.updates);
    await updatesKey.should(findsOneWidget);
    await updatesKey.tap();

    final newsCreateUpdatesKey = find.byKey(NewsUpdateKeys.addNewsUpdate);
    await newsCreateUpdatesKey.should(findsOneWidget);
    await newsCreateUpdatesKey.tap();

    final addImageSlideKey = find.byKey(NewsUpdateKeys.addImageSlide);
    await addImageSlideKey.should(findsOneWidget);

    // Adding Image Slide Object into Slide List
    final context = tester.element(addImageSlideKey);
    final ref = ProviderScope.containerOf(context);
    final imageFile =
        await convertAssetImageToXFile('assets/images/update_onboard.png');
    final slide = NewsSlideItem(
      type: NewsSlideType.image,
      mediaFile: imageFile,
    );
    ref.read(newsStateProvider.notifier).addSlide(slide);

    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    await selectSpace(spaceId, NewsUpdateKeys.selectSpace);

    await slideBackgroundColorKey.tap();

    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<void> createVideoNews(String spaceId) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final updatesKey = find.byKey(MainNavKeys.updates);
    await updatesKey.should(findsOneWidget);
    await updatesKey.tap();

    final newsCreateUpdatesKey = find.byKey(NewsUpdateKeys.addNewsUpdate);
    await newsCreateUpdatesKey.should(findsOneWidget);
    await newsCreateUpdatesKey.tap();

    final addVideoSlideKey = find.byKey(NewsUpdateKeys.addVideoSlide);
    await addVideoSlideKey.should(findsOneWidget);

    // Adding Video Slide Object into Slide List
    final context = tester.element(addVideoSlideKey);
    final ref = ProviderScope.containerOf(context);
    final videoFile = await convertAssetImageToXFile('assets/videos/video.mp4');
    final slide = NewsSlideItem(
      type: NewsSlideType.video,
      mediaFile: videoFile,
    );
    ref.read(newsStateProvider.notifier).addSlide(slide);

    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    await selectSpace(spaceId, NewsUpdateKeys.selectSpace);

    await slideBackgroundColorKey.tap();

    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();
  }

  Future<void> createMultipleNews(String spaceId, String text) async {
    await find.byKey(Keys.mainNav).should(findsOneWidget);
    final updatesKey = find.byKey(MainNavKeys.updates);
    await updatesKey.should(findsOneWidget);
    await updatesKey.tap();

    final newsCreateUpdatesKey = find.byKey(NewsUpdateKeys.addNewsUpdate);
    await newsCreateUpdatesKey.should(findsOneWidget);
    await newsCreateUpdatesKey.tap();

    // Adding text slide
    final addTextSlideKey = find.byKey(NewsUpdateKeys.addTextSlide);
    await addTextSlideKey.should(findsOneWidget);
    await addTextSlideKey.tap();

    // Change slide background color
    final slideBackgroundColorKey =
        find.byKey(NewsUpdateKeys.slideBackgroundColor);
    await slideBackgroundColorKey.should(findsOneWidget);
    await slideBackgroundColorKey.tap();

    // Open bottom sheet for adding more slide
    final addMoreNewsKey = find.byKey(NewsUpdateKeys.addNewsSlide);
    await addMoreNewsKey.should(findsOneWidget);
    await addMoreNewsKey.tap();

    // Adding Image Slide
    final addImageSlideKey = find.byKey(NewsUpdateKeys.addImageSlide);
    await addImageSlideKey.should(findsOneWidget);

    // Adding image slide object into slide list
    final imageSlideContext = tester.element(addImageSlideKey);
    final imageSlideRef = ProviderScope.containerOf(imageSlideContext);
    final imageFile =
        await convertAssetImageToXFile('assets/images/update_onboard.png');
    final imageSlide = NewsSlideItem(
      type: NewsSlideType.image,
      mediaFile: imageFile,
    );
    imageSlideRef.read(newsStateProvider.notifier).addSlide(imageSlide);

    // Close bottom sheet
    final cancelKey = find.byKey(NewsUpdateKeys.cancelButton);
    await cancelKey.should(findsOneWidget);
    await cancelKey.tap();

    // Change background color
    await slideBackgroundColorKey.tap();

    // Open bottom sheet for adding more slide
    await addMoreNewsKey.tap();

    // Adding video slide
    final addVideoSlideKey = find.byKey(NewsUpdateKeys.addVideoSlide);
    await addVideoSlideKey.should(findsOneWidget);

    // Adding video slide object into slide list
    final videoSlideContext = tester.element(addVideoSlideKey);
    final videoSlideRef = ProviderScope.containerOf(videoSlideContext);
    final videoFile = await convertAssetImageToXFile('assets/videos/video.mp4');
    final videoSlide = NewsSlideItem(
      type: NewsSlideType.video,
      mediaFile: videoFile,
    );
    videoSlideRef.read(newsStateProvider.notifier).addSlide(videoSlide);

    // Close bottom sheet
    await cancelKey.should(findsOneWidget);
    await cancelKey.tap();

    // Change background color
    await slideBackgroundColorKey.tap();

    // Submit news button
    final submit = find.byKey(NewsUpdateKeys.newsSubmitBtn);
    await tester.ensureVisible(submit);
    await submit.tap();

    // Remove new text slide
    final newsRemoveBtnKey = find.byKey(const Key('remove-slide-text-0'));
    await newsRemoveBtnKey.should(findsOneWidget);
    await newsRemoveBtnKey.tap();

    // Getting image slide in list
    final slideImageKey = find.byKey(const Key('slide-image-0'));
    await slideImageKey.should(findsOneWidget);
    await slideImageKey.tap();

    // Change background color
    await slideBackgroundColorKey.tap();

    // Getting video slide in list
    final slideVideoKey = find.byKey(const Key('slide-video-1'));
    await slideVideoKey.should(findsOneWidget);
    await slideVideoKey.tap();

    // Change background color
    await slideBackgroundColorKey.tap();

    // Open bottom sheet for adding more slide
    await addMoreNewsKey.tap();

    // Adding new text slide
    await addTextSlideKey.tap();

    // Getting first text slide in list
    final slideText1Key = find.byKey(const Key('slide-text-2'));
    await slideText1Key.should(findsOneWidget);

    // Submit news button
    await submit.tap();

    // Selecting space
    await selectSpace(spaceId, NewsUpdateKeys.selectSpace);

    // Submit news button
    await submit.tap();

    // Writing text to text slide
    final updateSlideTextField = find.byKey(NewsUpdateKeys.textSlideInputField);
    await updateSlideTextField.should(findsOneWidget);
    await updateSlideTextField.enterTextWithoutReplace(text);

    // Change background color
    await slideBackgroundColorKey.tap();

    // Submit news button
    await submit.tap();
  }
}

Future<XFile> convertAssetImageToXFile(String assetPath) async {
  // Load the asset as a byte data
  final byteData = await rootBundle.load(assetPath);

  // Create a temporary directory
  Directory tempDir = await Directory.systemTemp.createTemp();

  // Create a new file in the temporary directory
  final fileName = assetPath.split('/').last;
  final file = File('${tempDir.path}/$fileName');

  // Write the asset byte data to the file
  if (!(await file.exists())) {
    await file.create(recursive: true);
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );
  }

  // Return the file as an XFile
  return XFile(file.path);
}

void updateTests() {
  acterTestWidget('Single Text News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.createTextNews(spaceId, 'Welcome to the show');

    // we expect to be thrown to the news screen and see our latest item first:
    final textUpdateContent = find.byKey(NewsUpdateKeys.textUpdateContent);
    await textUpdateContent.should(findsOneWidget);
    await find.text('Welcome to the show').should(findsWidgets);
  });

  acterTestWidget('Single Image News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.createImageNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);
  });

  acterTestWidget('Single Video News Update', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.createVideoNews(spaceId);

    // we expect to be thrown to the news screen and see our latest item first:
    final videoUpdateContent = find.byKey(NewsUpdateKeys.videoNewsContent);
    await videoUpdateContent.should(findsOneWidget);
  });

  acterTestWidget('Multiple News Updates', (t) async {
    final spaceId = await t.freshAccountWithSpace();
    await t.createMultipleNews(spaceId, 'Welcome to the show');

    // we expect to be thrown to the news screen and see our latest item first:
    // For Image
    final imageUpdateContent = find.byKey(NewsUpdateKeys.imageUpdateContent);
    await imageUpdateContent.should(findsOneWidget);
  });
}
