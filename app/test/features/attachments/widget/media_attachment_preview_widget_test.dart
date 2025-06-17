import 'dart:io';

import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/attachments/widgets/media_attachment_preview_widget.dart';
import 'package:acter/features/attachments/widgets/media_thumbnail_preview_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('MediaAttachmentPreviewWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required List<File> selectedFiles,
    }) async {
      await tester.pumpProviderWidget(
        child: MediaAttachmentPreviewWidget(
          selectedFiles: selectedFiles,
          handleFileUpload: (files) async {},
        ),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    // Helper function to verify common widget elements
    void verifyCommonWidgetElements({
      required String fileName,
      required bool hasVideoPlayer,
      required bool hasImage,
      required int expectedIconCount,
      required int expectedIconButtonCount,
      IconData? expectedIcon,
      required List<File> selectedFiles,
    }) {
      // Check if file name is shown
      expect(find.text(fileName), findsOneWidget);

      // Check if video player is shown
      expect(
        find.byType(ActerVideoPlayer),
        hasVideoPlayer ? findsOneWidget : findsNothing,
      );

      // Check if image is shown
      expect(find.byType(Image), hasImage ? findsOneWidget : findsNothing);

      // Check if icons are shown
      expect(find.byType(Icon), findsNWidgets(expectedIconCount));
      expect(find.byType(IconButton), findsNWidgets(expectedIconButtonCount));

      // Check if expected icon is shown
      if (expectedIcon != null) {
        expect(find.byIcon(expectedIcon), findsOneWidget);
      }

      // Check if media thumbnail preview list is shown
      if (selectedFiles.isNotEmpty) {
        expect(find.byType(MediaThumbnailPreviewList), findsOneWidget);
      } else {
        expect(find.byType(MediaThumbnailPreviewList), findsNothing);
      }
    }

    testWidgets('should show image preview when type is image', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.png';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: true,
        expectedIconCount: 2, // Close button icon and send button icon
        expectedIconButtonCount: 2, // Close button and send button
        selectedFiles: selectedFiles,
      );
    });

    testWidgets(
      'should show video preview when type is video',
      (WidgetTester tester) async {
        final fileName = 'test.mp4';
        final selectedFiles = [File(fileName)];
        await createWidgetUnderTest(
          tester: tester,
          selectedFiles: selectedFiles,
        );

        // 2 because of Close button icon and send button icon
        final expectedIconCount = 2;
        // 2 because of Close button and send button
        final expectedIconButtonCount = 2;

        verifyCommonWidgetElements(
          fileName: fileName,
          hasVideoPlayer: true,
          hasImage: false,
          expectedIconCount: expectedIconCount,
          expectedIconButtonCount: expectedIconButtonCount,
          selectedFiles: selectedFiles,
        );
      },
      skip: true, // Video player causes platform channel issues in unit tests
    );

    testWidgets('should show file preview when type is file', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.txt';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: false,
        // File icon, close button icon, and send button icon
        expectedIconCount: 3,
        expectedIconButtonCount: 2,
        selectedFiles: selectedFiles,
      );
    });

    testWidgets('should show audio preview when type is audio', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.mp3';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      // 4 because of Audio icon, close button icon, send button icon and file preview icon
      final expectedIconCount = 4;
      // 3 because of Play/pause button, close button, and send button
      final expectedIconButtonCount = 3;

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: false,
        expectedIconCount: expectedIconCount,
        expectedIconButtonCount: expectedIconButtonCount,
        selectedFiles: selectedFiles,
      );
    });

    testWidgets('should handle multiple file selection', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test1.txt';
      final fileName2 = 'test2.pdf';
      final fileName3 = 'test3.docx';
      final selectedFiles = [File(fileName1), File(fileName2), File(fileName3)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      // selectedFiles.length for media attachment preview widget
      // + 2 because of Show in media attachment preview widget
      // and delete icon in media thumbnail preview list
      final selectedFilesCount = selectedFiles.length + 2;

      // + 2 because of Close button icon and send button icon
      final expectedIconCount = selectedFilesCount + 2;
      // 3 because of Close button, send button and delete button in media thumbnail preview list
      final expectedIconButtonCount = 3;

      verifyCommonWidgetElements(
        fileName: fileName1,
        hasVideoPlayer: false,
        hasImage: false,
        expectedIconCount: expectedIconCount,
        expectedIconButtonCount: expectedIconButtonCount,
        selectedFiles: selectedFiles,
      );
    });

    testWidgets('should display txt file preview for single file', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.txt';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      // 3 because of PDF file icon, close button icon, and send button icon
      final expectedIconCount = 3;
      // 2 because of Close button and send button
      final expectedIconButtonCount = 2;

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: false,
        expectedIconCount: expectedIconCount,
        expectedIconButtonCount: expectedIconButtonCount,
        expectedIcon: PhosphorIconsRegular.file,
        selectedFiles: selectedFiles,
      );
    });

    testWidgets('should display PDF file preview for single file', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.pdf';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      // 3 because of PDF file icon, close button icon, and send button icon
      final expectedIconCount = 3;
      // 2 because of Close button and send button
      final expectedIconButtonCount = 2;

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: false,
        expectedIconCount: expectedIconCount,
        expectedIconButtonCount: expectedIconButtonCount,
        expectedIcon: PhosphorIconsRegular.filePdf,
        selectedFiles: selectedFiles,
      );
    });

    testWidgets('should display docx file preview for single file', (
      WidgetTester tester,
    ) async {
      final fileName = 'test.docx';
      final selectedFiles = [File(fileName)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
      );

      // 3 because of PDF file icon, close button icon, and send button icon
      final expectedIconCount = 3;
      // 2 because of Close button and send button
      final expectedIconButtonCount = 2;

      verifyCommonWidgetElements(
        fileName: fileName,
        hasVideoPlayer: false,
        hasImage: false,
        expectedIconCount: expectedIconCount,
        expectedIconButtonCount: expectedIconButtonCount,
        expectedIcon: PhosphorIconsRegular.fileDoc,
        selectedFiles: selectedFiles,
      );
    });
  });
}
