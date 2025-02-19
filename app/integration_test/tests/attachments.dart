import 'dart:typed_data';

import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show AttachmentDraft;
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mime/mime.dart';

import '../support/setup.dart';
import '../support/spaces.dart';
import '../support/util.dart';
import 'pins.dart';

extension ActerAttachments on ConvenientTest {
  Future<AttachmentDraft> imageAttachmentDraft({String? filepath}) async {
    // ensure attachments exists and permissible to post
    final attachmentsFinder =
        find.byKey(AttachmentSectionWidget.attachmentsKey);
    final attachmentWidget = attachmentsFinder.evaluate().first.widget
        as FoundAttachmentSectionWidget;
    final attachmentsManager = attachmentWidget.attachmentManager;
    await attachmentsFinder.should(findsOneWidget);
    final addAttachmentFinder =
        find.byKey(AttachmentSectionWidget.addAttachmentBtnKey);
    await addAttachmentFinder.should(findsOneWidget);
    //
    final imageFile = await convertAssetImageToXFile(
      filepath ?? 'assets/images/update_onboard.png',
    );
    final context = tester.element(addAttachmentFinder);
    final ref = ProviderScope.containerOf(context);
    final client = await ref.read(alwaysClientProvider.future);

    Uint8List bytes = await imageFile.readAsBytes();
    final decodedImage = await decodeImageFromList(bytes);
    final imageDraft = client
        .imageDraft(imageFile.path, 'image/')
        .size(bytes.length)
        .width(decodedImage.width)
        .height(decodedImage.height);
    final attachmentDraft = await attachmentsManager.contentDraft(imageDraft);
    return attachmentDraft;
  }

  Future<AttachmentDraft> videoAttachmentDraft({String? filepath}) async {
    // ensure attachments exists and permissible to post
    final attachmentsFinder =
        find.byKey(AttachmentSectionWidget.attachmentsKey);
    await attachmentsFinder.should(findsOneWidget);
    final attachmentWidget = attachmentsFinder.evaluate().first.widget
        as FoundAttachmentSectionWidget;
    final attachmentsManager = attachmentWidget.attachmentManager;
    final addAttachmentFinder =
        find.byKey(AttachmentSectionWidget.addAttachmentBtnKey);
    await addAttachmentFinder.should(findsOneWidget);
    //
    final videoFile = await convertAssetImageToXFile(
      filepath ?? 'assets/videos/video.mp4',
    );
    final context = tester.element(addAttachmentFinder);
    final ref = ProviderScope.containerOf(context);
    final client = await ref.read(alwaysClientProvider.future);

    Uint8List bytes = await videoFile.readAsBytes();
    final videoDraft =
        client.videoDraft(videoFile.path, 'video/').size(bytes.length);
    final attachmentDraft = await attachmentsManager.contentDraft(videoDraft);
    return attachmentDraft;
  }

  Future<AttachmentDraft> fileAttachmentDraft({String? filepath}) async {
    // ensure attachments exists and permissible to post
    final attachmentsFinder =
        find.byKey(AttachmentSectionWidget.attachmentsKey);
    await attachmentsFinder.should(findsOneWidget);
    final attachmentWidget = attachmentsFinder.evaluate().first.widget
        as FoundAttachmentSectionWidget;
    final attachmentsManager = attachmentWidget.attachmentManager;

    final addAttachmentFinder =
        find.byKey(AttachmentSectionWidget.addAttachmentBtnKey);
    await addAttachmentFinder.should(findsOneWidget);
    //
    final file = await convertAssetImageToXFile(
      filepath ?? 'assets/videos/video.mp4',
    );
    final context = tester.element(addAttachmentFinder);
    final ref = ProviderScope.containerOf(context);
    final client = await ref.read(alwaysClientProvider.future);
    String? mimeType = lookupMimeType(file.path);
    String fileName = file.path.split('/').last;
    int fileSize = await file.length();
    final fileDraft = client
        .fileDraft(file.path, mimeType!)
        .filename(fileName)
        .size(fileSize);
    final attachmentDraft = await attachmentsManager.contentDraft(fileDraft);
    return attachmentDraft;
  }
}

void attachmentTests() {
  acterTestWidget('Add attachment to created pin example', (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Pins Attachments Example',
    );

    await t.createPin(
      spaceId,
      'Pin with attachment example',
      'This pin contains attachment',
      'https://acter.global',
    );

    // we expect to be thrown to the pin screen and see our title
    await find.text('Pin with attachment example').should(findsAtLeast(1));

    // create attachment drafts
    final imageDraft = await t.imageAttachmentDraft();
    final videoDraft = await t.videoAttachmentDraft();

    // send attachments
    final imageAttachmentId = await imageDraft.send();
    final videoAttachmentId = await videoDraft.send();

    final imageAttachmentKey = find.byKey(Key(imageAttachmentId.toString()));
    await imageAttachmentKey.should(findsOneWidget);
    final videoAttachmentKey = find.byKey(Key(videoAttachmentId.toString()));
    await videoAttachmentKey.should(findsOneWidget);
  });

  acterTestWidget(
      'Add attachment and user can see main attachment on pin in pins overview',
      (t) async {
    final spaceId = await t.freshAccountWithSpace(
      userDisplayName: 'Alex',
      spaceDisplayName: 'Main Attachment on pin card example',
    );

    await t.createPin(
      spaceId,
      'Attachment on pin item example',
      'This pin contains attachment',
      'https://acter.global',
    );

    // we expect to be thrown to the pin screen and see our title
    await find.text('Attachment on pin item example').should(findsAtLeast(1));

    final imageDraft = await t.imageAttachmentDraft();
    final imageAttachmentId = await imageDraft.send();

    await t.navigateTo([
      MainNavKeys.quickJump,
      QuickJumpKeys.pins,
    ]);

    // we expect to see our pin in list
    await find.text('Attachment on pin item example').should(findsAtLeast(1));

    // we expect to see attachment showing on pin item
    final imageAttachmentKey = find.byKey(Key(imageAttachmentId.toString()));
    await imageAttachmentKey.should(findsOneWidget);
  });

  acterTestWidget(
    'can delete attachment from pin and verify it no longer shows up',
    (t) async {
      final spaceId = await t.freshAccountWithSpace(
        userDisplayName: 'Alex',
        spaceDisplayName: 'Delete attachment example',
      );

      await t.createPin(
        spaceId,
        'Delete attachment from pin example',
        'This pin contains attachment and can be deleted',
        'https://acter.global',
      );

      final fileDraft = await t.fileAttachmentDraft();
      final fileAttachmentId = await fileDraft.send();

      // we assure that file attachment exists
      final fileAttachmentKey = find.byKey(Key(fileAttachmentId.toString()));
      await fileAttachmentKey.should(findsOneWidget);

      final redactBtn = find.byKey(AttachmentSectionWidget.redactBtnKey);
      await redactBtn.should(findsOneWidget);
      await redactBtn.tap();

      final confirmRedactBtn =
          find.byKey(AttachmentSectionWidget.confirmRedactKey);
      await confirmRedactBtn.should(findsOneWidget);
      await confirmRedactBtn.tap();

      // confirm that isn't there anymore...
      await fileAttachmentKey.should(findsNothing);
    },
  );
}
