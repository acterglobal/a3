import 'package:acter/common/actions/select_space.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/task/taskList_selector_drawer.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Allows the user to select a tasklist. If no space is
/// selected prior, it will ask to select a space first.
/// Returns the tasList if the user selected one or `null`
/// if they didn't.
Future<TaskList?> selectTaskList({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final lang = L10n.of(context);
  String? spaceId = ref.read(selectedSpaceIdProvider);
  spaceId ??= await selectSpace(
    context: context,
    ref: ref,
    canCheck: (m) => m?.canString('CanPostTask') == true,
  );
  if (!context.mounted) return null;

  if (spaceId == null) {
    EasyLoading.showError(
      lang.pleaseSelectSpace,
      duration: const Duration(seconds: 2),
    );
    return null;
  }

  final taskListId = await selectTaskListDrawer(
    context: context,
    spaceId: spaceId,
  );
  if (!context.mounted) return null;
  if (taskListId == null) {
    return null;
  }

  return await ref.read(taskListProvider(taskListId).future);
}
