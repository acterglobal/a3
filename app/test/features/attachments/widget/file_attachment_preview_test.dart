import 'dart:io';

import 'package:acter/features/attachments/widgets/file_attachment_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('FileAttachmentPreview Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required File file,
    }) async {
      await tester.pumpProviderWidget(child: FileAttachmentPreview(file: file));
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show image preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.png'));
      expect(find.byIcon(PhosphorIconsRegular.file), findsOneWidget);
    });

    testWidgets('should show video preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.mp4'));
      expect(find.byIcon(PhosphorIconsRegular.file), findsOneWidget);
    });

    testWidgets('should show audio preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.mp3'));
      expect(find.byIcon(PhosphorIconsRegular.file), findsOneWidget);
    });

    testWidgets('should show txt preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.txt'));
      expect(find.byIcon(PhosphorIconsRegular.file), findsOneWidget);
    });

    testWidgets('should show pdf preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.pdf'));
      expect(find.byIcon(PhosphorIconsRegular.filePdf), findsOneWidget);
    });

    testWidgets('should show doc preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.doc'));
      expect(find.byIcon(PhosphorIconsRegular.fileDoc), findsOneWidget);
    });

    testWidgets('should show docx preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.docx'));
      expect(find.byIcon(PhosphorIconsRegular.fileDoc), findsOneWidget);
    });

    testWidgets('should show xls preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.xls'));
      expect(find.byIcon(PhosphorIconsRegular.fileXls), findsOneWidget);
    });

    testWidgets('should show xlsx preview when type is file', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, file: File('test.xlsx'));
      expect(find.byIcon(PhosphorIconsRegular.fileXls), findsOneWidget);
    });
  });
}
