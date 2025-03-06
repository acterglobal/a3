import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/pins/actions/pin_update_actions.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showEditPintTitleDialog(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
) {
  final lang = L10n.of(context);
  showEditTitleBottomSheet(
    context: context,
    bottomSheetTitle: L10n.of(context).editName,
    titleValue: pin.title(),
    onSave: (ref, newTitle) async {
      final pinEditNotifier = ref.read(pinEditProvider(pin).notifier);
      pinEditNotifier.setTitle(newTitle);
      updatePinTitle(context, ref, pin, newTitle);
      await autosubscribe(ref: ref, objectId: pin.eventIdStr(), lang: lang);
    },
  );
}

void showEditPintDescriptionDialog(
  BuildContext context,
  WidgetRef ref,
  ActerPin pin,
) {
  final lang = L10n.of(context);
  showEditHtmlDescriptionBottomSheet(
    context: context,
    descriptionHtmlValue: pin.content()?.formattedBody(),
    descriptionMarkdownValue: pin.content()?.body(),
    onSave: (ref, htmlBodyDescription, plainDescription) async {
      updatePinDescription(
        context,
        ref,
        htmlBodyDescription,
        plainDescription,
        pin,
      );

      await autosubscribe(ref: ref, objectId: pin.eventIdStr(), lang: lang);
    },
  );
}
