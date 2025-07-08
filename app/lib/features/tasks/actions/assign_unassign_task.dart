 import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:logging/logging.dart';

final _log = Logger('AssignUnassignTask');

Future<void> onAssign(BuildContext context, WidgetRef ref, Task task) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.assigningSelf);
    try {
      await task.assignSelf();
      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      EasyLoading.showToast(lang.assignedYourself);
    } catch (e, s) {
      _log.severe('Failed to self-assign task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToAssignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onUnAssign(BuildContext context, WidgetRef ref, Task task) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.unassigningSelf);
    try {
      await task.unassignSelf();
      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      EasyLoading.showToast(lang.assignmentWithdrawn);
    } catch (e, s) {
      _log.severe('Failed to self-unassign task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToUnassignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }