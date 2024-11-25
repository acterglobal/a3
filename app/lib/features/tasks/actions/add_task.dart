import 'package:acter/features/tasks/actions/select_tasklist.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_task');

Future<(String, String)?> addTask({
  required BuildContext context,
  required WidgetRef ref,
  TaskList? taskList,
  required String title,
  String? description,
  DateTime? dueDate,
}) async {
  final lang = L10n.of(context);

  taskList ??= await selectTaskList(context: context, ref: ref);
  if (taskList == null) {
    EasyLoading.showError(
      lang.selectTaskList,
      duration: const Duration(seconds: 2),
    );
    return null;
  }

  EasyLoading.show(status: lang.addingTask);
  final taskDraft = taskList.taskBuilder();
  taskDraft.title(title);
  if (description != null && description.isNotEmpty == true) {
    taskDraft.descriptionText(description);
  }
  if (dueDate != null) {
    taskDraft.dueDate(dueDate.year, dueDate.month, dueDate.day);
  }
  try {
    final eventId = await taskDraft.send();
    EasyLoading.dismiss();
    return (taskList.eventIdStr(), eventId.toString());
  } catch (e, s) {
    _log.severe('Failed to create task', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.showError(
        lang.creatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
    return null;
  }
}
