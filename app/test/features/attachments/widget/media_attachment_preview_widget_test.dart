import 'dart:io';

import 'package:acter/common/models/types.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/attachments/widgets/media_attachment_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('MediaAttachmentPreviewWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required List<File> selectedFiles,
      required AttachmentType type,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [],
        child: MediaAttachmentPreviewWidget(
          selectedFiles: selectedFiles,
          type: type,
          handleFileUpload: (files, type) async {},
        ),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show image preview when type is image', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: [File('test.png')],
        type: AttachmentType.image,
      );
      expect(find.text('test.png'), findsOneWidget);
      expect(
        find.byType(SizedBox),
        findsWidgets,
      ); // Widget contains SizedBox widgets for spacing
      expect(find.byType(ActerVideoPlayer), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(
        find.byType(Icon),
        findsNWidgets(2),
      ); // Close button icon and send button icon
      expect(
        find.byType(IconButton),
        findsNWidgets(2),
      ); // Close button and send button
    });

    testWidgets(
      'should show video preview when type is video',
      (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          selectedFiles: [File('test.mp4')],
          type: AttachmentType.video,
        );
        expect(find.text('test.mp4'), findsOneWidget);
        expect(
          find.byType(SizedBox),
          findsWidgets,
        ); // Widget contains SizedBox widgets for spacing
        expect(find.byType(ActerVideoPlayer), findsOneWidget);
        expect(find.byType(Image), findsNothing);
        // Skip icon and button checks for video since ActerVideoPlayer causes platform issues in tests
      },
      skip: true, // Video player causes platform channel issues in unit tests
    );

    testWidgets('should show unsupported file type when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        selectedFiles: [File('test.txt')],
        type: AttachmentType.file,
      );
      expect(find.text('test.txt'), findsOneWidget);
      expect(
        find.byType(SizedBox),
        findsWidgets,
      ); // Widget contains SizedBox widgets for spacing
      expect(find.byType(ActerVideoPlayer), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        find.byType(Icon),
        findsNWidgets(3),
      ); // Warning icon, close button icon, and send button icon
      expect(
        find.byType(IconButton),
        findsNWidgets(2),
      ); // Close button and send button
    });
  });
}
