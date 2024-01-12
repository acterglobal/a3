import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:dart_date/dart_date.dart';
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
      if (widget.noneChild != null) {
        return widget.noneChild!;
      } else {
        return const SizedBox.shrink();
      }
    }

    String? label;
    TextStyle? dueTheme;

    if (dueDate!.isToday) {
      label = 'due today';
    } else if (dueDate!.isTomorrow) {
      label = 'due tomorrow';
    } else if (dueDate!.isPast) {
      label = dueDate!.timeago();
      dueTheme = textStyle.copyWith(
        color: Theme.of(context).colorScheme.taskOverdueFG,
      );
    }

    return Chip(
      visualDensity: widget.visualDensity,
      label: Text(
        // FIXME: tooltip to show the full date?
        label ??
            'due: ${DateFormat(DateFormat.YEAR_MONTH_WEEKDAY_DAY).format(dueDate!)}',
        style: widget.task.isDone() ? null : dueTheme,
      ),
    );
  }

  Future<void> duePickerAction(BuildContext context) async {
    final newDue = await DuePicker.showPicker(
      context: context,
      initialDate: dueDate,
    ); // FIXME: add unsetting support
    if (newDue == null) {
      return;
    }
    EasyLoading.show(status: 'Updating due');
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
      EasyLoading.showToast(
        'Due successfully changed',
        toastPosition: EasyLoadingToastPosition.bottom,
      );
    } catch (e) {
      EasyLoading.showError('Updating due failed: $e');
    }
  }
}
