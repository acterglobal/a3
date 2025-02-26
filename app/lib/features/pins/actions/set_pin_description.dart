import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showEditPinDescriptionBottomSheet({
  required BuildContext context,
  bool isBottomSheetOpen = false,
  String? htmlBodyDescription,
  String? plainDescription,
}) {
  showEditHtmlDescriptionBottomSheet(
    bottomSheetTitle: L10n.of(context).add,
    context: context,
    descriptionHtmlValue: htmlBodyDescription,
    descriptionMarkdownValue: plainDescription,
    onSave: (ref, htmlBodyDescription, plainDescription) {
      if (isBottomSheetOpen) Navigator.pop(context);
      Navigator.pop(context);
      ref.read(createPinStateProvider.notifier).setDescriptionValue(
            htmlBodyDescription: htmlBodyDescription,
            plainDescription: plainDescription,
          );
    },
  );
}
