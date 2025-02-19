import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::set_space_title');

void showEditSpaceNameBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String spaceId,
}) {
  final lang = L10n.of(context);
  final spaceAvatarInfo = ref.read(roomAvatarInfoProvider(spaceId));
  if (!context.mounted) return;

  showEditTitleBottomSheet(
    context: context,
    bottomSheetTitle: lang.editName,
    titleValue: spaceAvatarInfo.displayName ?? '',
    onSave: (ref, newName) async {
      try {
        EasyLoading.show(status: lang.updateName);
        final space = await ref.read(spaceProvider(spaceId).future);
        await space.setName(newName);
        EasyLoading.dismiss();
        if (!context.mounted) return;
        Navigator.pop(context);
      } catch (e, s) {
        _log.severe('Failed to edit space name', e, s);
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.updateNameFailed(e),
          duration: const Duration(seconds: 3),
        );
      }
    },
  );
}
