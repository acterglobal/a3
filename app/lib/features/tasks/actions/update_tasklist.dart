import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::update_tasklist_details');

Future<void> updateTaskListIcon(
    BuildContext context,
    WidgetRef ref,
    TaskList taskList,
    Color color,
    ActerIcon acterIcon,
) async {
  EasyLoading.show(status: L10n.of(context).updatingIcon);

  // TaskList IconData
  final sdk = await ref.watch(sdkProvider.future);
  final displayBuilder = sdk.api.newDisplayBuilder();
  displayBuilder.color(color.value);
  displayBuilder.icon('acter-icon', acterIcon.name);

  final updateBuilder = taskList.updateBuilder();
  updateBuilder.display(displayBuilder.build());

  try {
    await updateBuilder.send();
    EasyLoading.dismiss();
    ref.invalidate(taskListProvider);
    if (!context.mounted) return;
  } catch (e, s) {
    _log.severe('Failed to rename tasklist', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).updatingTaskFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> updateTaskListTitle(
    BuildContext context,
    TaskList taskList,
    String newName,
    ) async {
  EasyLoading.show(status: L10n.of(context).updatingTask);
  final updater = taskList.updateBuilder();
  updater.name(newName);
  try {
    await updater.send();
    EasyLoading.dismiss();
    if (!context.mounted) return;
    Navigator.pop(context);
  } catch (e, s) {
    _log.severe('Failed to rename tasklist', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).updatingTaskFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
