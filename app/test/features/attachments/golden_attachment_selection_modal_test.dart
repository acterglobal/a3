import 'package:acter/common/dialogs/bottom_sheet_container_widget.dart';
import 'package:acter/features/attachments/widgets/attachment_selection_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        child: BottomSheetContainerWidget(
          child: AttachmentSelectionOptions(
            onSelected: (files, type) async {},
            onLinkSelected: (title, link) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(BottomSheetContainerWidget),
      matchesGoldenFile('goldens/attachment_selection_modal.png'),
    );
  });
}
