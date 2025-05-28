import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/attachments/actions/select_attachment.dart';
import '../../helpers/test_util.dart';
import '../../helpers/font_loader.dart';

typedef OnAttachmentSelected =
    Future<void> Function(List files, dynamic attachmentType);
typedef OnLinkSelected = Future<void> Function(String title, String link);

void main() {
  testWidgets('AttachmentSelectionModal golden', (tester) async {
    await loadTestFonts();
    await tester.pumpProviderWidget(
      child: Material(
        child: AttachmentSelectionModal(
          onSelected: (files, type) async {},
          onLinkSelected: (title, link) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(AttachmentSelectionModal),
      matchesGoldenFile('goldens/attachment_selection_modal.png'),
    );
  });
}
