import 'dart:io';

import 'package:acter/features/attachments/widgets/file_attachment_preview.dart';
import 'package:acter/features/attachments/widgets/media_thumbnail_preview_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

enum WidgetType { image, video, audio, file }

void main() {
  group('FileAttachmentPreview Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required List<File> selectedFiles,
      int currentIndex = 0,
    }) async {
      await tester.pumpProviderWidget(
        child: MediaThumbnailPreviewList(
          selectedFiles: selectedFiles,
          currentIndex: currentIndex,
          onPageChanged: (index) {},
          onDeleted: (index) {},
        ),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    void verifyListViewAndWidgets({
      required WidgetTester tester,
      required List<File> selectedFiles,
      required WidgetType widgetType,
    }) async {
      expect(find.byType(ListView), findsOneWidget);

      switch (widgetType) {
        case WidgetType.image:
          expect(find.byType(Image), findsNWidgets(selectedFiles.length));
          break;
        case WidgetType.video:
          expect(find.byType(Image), findsNWidgets(selectedFiles.length));
          break;
        case WidgetType.audio:
          expect(
            find.byIcon(Atlas.music_file),
            findsNWidgets(selectedFiles.length),
          );
          break;
        case WidgetType.file:
          expect(
            find.byType(FileAttachmentPreview),
            findsNWidgets(selectedFiles.length),
          );
          expect(find.byIcon(PhosphorIconsRegular.filePdf), findsOneWidget);
          expect(find.byIcon(PhosphorIconsRegular.fileDoc), findsOneWidget);
          break;
      }
    }

    testWidgets('should show image preview when type is image', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.png';
      final fileName2 = 'test2.png';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(tester: tester, selectedFiles: selectedFiles);
      verifyListViewAndWidgets(
        tester: tester,
        selectedFiles: selectedFiles,
        widgetType: WidgetType.image,
      );
    });

    testWidgets('should show video preview when type is video', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.mp4';
      final fileName2 = 'test2.mp4';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(tester: tester, selectedFiles: selectedFiles);
      verifyListViewAndWidgets(
        tester: tester,
        selectedFiles: selectedFiles,
        widgetType: WidgetType.video,
      );
    }, skip: true);

    testWidgets('should show audio preview when type is audio', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.mp3';
      final fileName2 = 'test2.mp3';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(tester: tester, selectedFiles: selectedFiles);
      verifyListViewAndWidgets(
        tester: tester,
        selectedFiles: selectedFiles,
        widgetType: WidgetType.audio,
      );
    });

    testWidgets('should show file preview when type is file', (
      WidgetTester tester,
    ) async {
      final fileName1 = 'test.pdf';
      final fileName2 = 'test2.docx';
      final selectedFiles = [File(fileName1), File(fileName2)];
      await createWidgetUnderTest(tester: tester, selectedFiles: selectedFiles);
      verifyListViewAndWidgets(
        tester: tester,
        selectedFiles: selectedFiles,
        widgetType: WidgetType.file,
      );
    });
  });
}
