import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/edit_plain_description_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showEditDescriptionBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String spaceId,
}) async {
  final space = await ref.read(spaceProvider(spaceId).future);
  if (!context.mounted) return;
  showEditPlainDescriptionBottomSheet(
    context: context,
    descriptionValue: space.topic() ?? '',
    onSave: (newDescription) async {
      try {
        EasyLoading.show(status: L10n.of(context).updateDescription);
        await space.setTopic(newDescription);
        EasyLoading.dismiss();
        if (!context.mounted) return;
        Navigator.pop(context);
      } catch (e) {
        EasyLoading.dismiss();
        if (!context.mounted) return;
        EasyLoading.showError(L10n.of(context).updateDescriptionFailed(e));
      }
    },
  );
}
