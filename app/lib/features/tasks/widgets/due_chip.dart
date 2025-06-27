import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/home/providers/task_providers.dart';

final _log = Logger('a3::tasks::widgets::due_clip');

class DueChip extends ConsumerStatefulWidget {
  final Task task;
  final Widget? noneChild;
  final bool canChange;
  final TextStyle? baseTextStyle;
  final VisualDensity? visualDensity;

  const DueChip({
    super.key,
    required this.task,
    this.canChange = false,
    this.noneChild,
    this.baseTextStyle,
    this.visualDensity,
  });

  @override
  ConsumerState<DueChip> createState() => _DueChipState();
}

class _DueChipState extends ConsumerState<DueChip> {
  DateTime? dueDate;

  @override
  void initState() {
    super.initState();
    final dueDateStr = widget.task.dueDate();
    if (dueDateStr != null) {
      dueDate = DateTime.parse(dueDateStr);
    } else {
      dueDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.canChange) {
      return InkWell(
        child: inner(context),
        onTap: () async {
          await duePickerAction(context);
        },
      );
    } else {
      return inner(context);
    }
  }

  Widget inner(BuildContext context) {
    final lang = L10n.of(context);
    final textStyle =
        widget.baseTextStyle ?? Theme.of(context).textTheme.bodySmall;
    return dueDate.map((date) {
          final dateText = DateFormat(
            DateFormat.YEAR_MONTH_WEEKDAY_DAY,
          ).format(date);
          final label =
              date.isToday
                  ? lang.dueToday
                  : date.isTomorrow
                  ? lang.dueTomorrow
                  : date.isPast
                  ? date.timeago()
                  : lang.due(dateText);
          final dueTheme =
              date.isPast
                  ? textStyle?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  )
                  : null;
          return Chip(
            visualDensity: widget.visualDensity,
            label: Text(
              // FIXME: tooltip to show the full date?
              label,
              style: widget.task.isDone() ? null : dueTheme,
            ),
          );
        }) ??
        widget.noneChild ??
        const SizedBox.shrink();
  }

  Future<void> duePickerAction(BuildContext context) async {
    final lang = L10n.of(context);
    final newDue = await showDuePicker(
      context: context,
      initialDate: dueDate,
    ); // FIXME: add unsetting support
    if (!context.mounted) return;
    if (newDue == null) return;
    EasyLoading.show(status: lang.updatingDue);
    try {
      final updater =
          widget.task.updateBuilder()
            ..dueDate(newDue.due.year, newDue.due.month, newDue.due.day);
      if (newDue.includeTime) {
        final seconds =
            newDue.due.hour * 60 * 60 +
            newDue.due.minute * 60 +
            newDue.due.second;
        // adapt the timezone value
        updater.utcDueTimeOfDay(seconds + newDue.due.timeZoneOffset.inSeconds);
      } else if (widget.task.utcDueTimeOfDay() != null) {
        // we have one, we need to reset it
        updater.unsetUtcDueTimeOfDay();
      }
      await updater.send();

      // Invalidate both providers to ensure proper task reordering
      ref.invalidate(myOpenTasksProvider);

      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.dueSuccess);
    } catch (e, s) {
      _log.severe('Failed to change due date of task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.updatingDueFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
