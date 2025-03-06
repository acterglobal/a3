import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::actions::update_tasklist');

Future<void> updateTaskListIcon(
  BuildContext context,
  WidgetRef ref,
  TaskList taskList,
  Color color,
  ActerIcon acterIcon,
) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.updatingIcon);

  // TaskList IconData
  final sdk = await ref.watch(sdkProvider.future);
  final displayBuilder = sdk.api.newDisplayBuilder();
  displayBuilder.color(color.toInt());
  displayBuilder.icon('acter-icon', acterIcon.name);

  final updateBuilder = taskList.updateBuilder();
  updateBuilder.display(displayBuilder.build());

  try {
    await updateBuilder.send();

    await autosubscribe(ref: ref, objectId: taskList.eventIdStr(), lang: lang);
    EasyLoading.dismiss();
    ref.invalidate(taskListsProvider);
    if (!context.mounted) return;
  } catch (e, s) {
    _log.severe('Failed to rename tasklist', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.updatingTaskFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}

Future<void> updateTaskListTitle(
  BuildContext context,
  WidgetRef ref,
  TaskList taskList,
  String newName,
) async {
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.updatingTask);
  final updater = taskList.updateBuilder();
  updater.name(newName);
  try {
    await updater.send();
    await autosubscribe(ref: ref, objectId: taskList.eventIdStr(), lang: lang);
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
      lang.updatingTaskFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
