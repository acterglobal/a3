import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:intl/intl.dart';

class DueChip extends StatefulWidget {
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
  State<DueChip> createState() => _DueChipState();
}

class _DueChipState extends State<DueChip> {
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
    final textStyle =
        widget.baseTextStyle ?? Theme.of(context).textTheme.bodySmall!;
    if (dueDate == null) {
      return widget.noneChild ?? const SizedBox.shrink();
    }

    String? label;
    TextStyle? dueTheme;

    if (dueDate!.isToday) {
      label = L10n.of(context).dueToday;
    } else if (dueDate!.isTomorrow) {
      label = L10n.of(context).dueTomorrow;
    } else if (dueDate!.isPast) {
      label = dueDate!.timeago();
      dueTheme = textStyle.copyWith(
        color: Theme.of(context).colorScheme.taskOverdueFG,
      );
    }
    final dateText =
        DateFormat(DateFormat.YEAR_MONTH_WEEKDAY_DAY).format(dueDate!);

    return Chip(
      visualDensity: widget.visualDensity,
      label: Text(
        // FIXME: tooltip to show the full date?
        label ?? L10n.of(context).due(dateText),
        style: widget.task.isDone() ? null : dueTheme,
      ),
    );
  }

  Future<void> duePickerAction(BuildContext context) async {
    final newDue = await DuePicker.showPicker(
      context: context,
      initialDate: dueDate,
    ); // FIXME: add unsetting support
    if (!context.mounted) return;
    if (newDue == null) return;
    EasyLoading.show(status: L10n.of(context).updatingDue);
    try {
      final updater = widget.task.updateBuilder();
      updater.dueDate(newDue.due.year, newDue.due.month, newDue.due.day);
      if (newDue.includeTime) {
        final seconds = newDue.due.hour * 60 * 60 +
            newDue.due.minute * 60 +
            newDue.due.second;
        // adapt the timezone value
        updater.utcDueTimeOfDay(seconds + newDue.due.timeZoneOffset.inSeconds);
      } else if (widget.task.utcDueTimeOfDay() != null) {
        // we have one, we need to reset it
        updater.unsetUtcDueTimeOfDay();
      }
      await updater.send();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).dueSuccess);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updatingDueFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
