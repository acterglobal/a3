import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/features/attachments/widgets/file_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/media_thumbnail_preview_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('FileAttachmentPreview Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required List<File> selectedFiles,
      required AttachmentType type,
      int currentIndex = 0,
    }) async {
      await tester.pumpProviderWidget(
        child: MediaThumbnailPreviewList(
          selectedFiles: selectedFiles,
          type: type,
          currentIndex: currentIndex,
          onPageChanged: (index) {},
          onDeleted: (index) {},
        ),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show image preview when type is image', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.png';
      final fileName2 = 'test2.png';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
        type: AttachmentType.image,
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Image), findsNWidgets(selectedFiles.length));
    });

    testWidgets('should show video preview when type is video', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.mp4';
      final fileName2 = 'test2.mp4';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
        type: AttachmentType.video,
      );
      expect(find.byType(ListView), findsOneWidget);
      // Check if video player is shown
      // Then it show video thumbnail image
      expect(find.byType(Image), findsNWidgets(selectedFiles.length));
    }, skip: true);

    testWidgets('should show audio preview when type is audio', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.mp3';
      final fileName2 = 'test2.mp3';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
        type: AttachmentType.audio,
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.fileAudio), findsNWidgets(selectedFiles.length));
    });

    testWidgets('should show file preview when type is file', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.pdf';
      final fileName2 = 'test2.docx';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: selectedFiles,
        type: AttachmentType.file,
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(FileAttachmentPreview), findsNWidgets(selectedFiles.length));
      expect(find.byIcon(PhosphorIconsRegular.filePdf), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.fileDoc), findsOneWidget);
    });
  });
}
