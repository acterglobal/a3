import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/features/pins/actions/pin_update_actions.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showEditPintTitleDialog(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
) {
  showEditTitleBottomSheet(
    context: context,
    bottomSheetTitle: L10n.of(context).editName,
    titleValue: pin.title(),
    onSave: (newTitle) async {
      final pinEditNotifier = ref.read(pinEditProvider(pin).notifier);
      pinEditNotifier.setTitle(newTitle);
      updatePinTitle(context, pin, newTitle);
    },
  );
}

void showEditPintDescriptionDialog(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
) {
  showEditHtmlDescriptionBottomSheet(
    context: context,
    descriptionHtmlValue: pin.content()?.formattedBody(),
    descriptionMarkdownValue: pin.content()?.body(),
    onSave: (htmlBodyDescription, plainDescription) async {
      updatePinDescription(
        context,
        htmlBodyDescription,
        plainDescription,
        pin,
      );
    },
  );
}
