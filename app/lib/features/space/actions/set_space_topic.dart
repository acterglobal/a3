import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/edit_plain_description_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::set_topic');

void showEditDescriptionBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String spaceId,
}) async {
  final lang = L10n.of(context);
  final space = await ref.read(spaceProvider(spaceId).future);
  if (!context.mounted) return;
  showEditPlainDescriptionBottomSheet(
    context: context,
    descriptionValue: space.topic() ?? '',
    onSave: (newDescription) async {
      try {
        EasyLoading.show(status: lang.updateDescription);
        await space.setTopic(newDescription);
        EasyLoading.dismiss();
        if (!context.mounted) return;
        Navigator.pop(context);
      } catch (e, s) {
        _log.severe('Failed to change space topic', e, s);
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.updateDescriptionFailed(e),
          duration: const Duration(seconds: 3),
        );
      }
    },
  );
}
