import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:jiffy/jiffy.dart';
import 'dart:core';

class TaskInfo extends ConsumerWidget {
  static const statusBtnNotDone = Key('task-info-status-not-done');
  static const statusBtnDone = Key('task-info-status-done');
  static const dueDateField = Key('task-due-field');
  final Task task;
  const TaskInfo({Key? key, required this.task}) : super(key: key);

  Future<void> duePicker(BuildContext context, DateTime? currentDue) async {
    final newDue = await DuePicker.showPicker(
        context: context,
        initialDate: currentDue); // FIXME: add unsetting support
    if (newDue == null) {
      return;
    }
    final updater = task.updateBuilder();
    updater.utcDueFromRfc3339(newDue.due.toIso8601String());
    updater.showWithoutTime(!newDue.includeTime);
    await updater.send();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> body = [];
    final dueDate = task.utcDueRfc3339();
    final isDone = task.isDone();
    if (dueDate == null) {
      body.add(
        ListTile(
          key: dueDateField,
          dense: true,
          onTap: () async {
            await duePicker(context, null);
          },
          subtitle: const Text('Due'),
          title: Text(
            '(None)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w100,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.brandColorScheme.neutral5,
                ),
          ),
        ),
      );
    } else {
      final due = Jiffy.parse(dueDate);
      final now = Jiffy.now();
      if (due.isBefore(now)) {
        body.add(
          ListTile(
            key: dueDateField,
            dense: true,
            onTap: () async {
              await duePicker(context, due.dateTime);
            },
            title: Tooltip(
              message: due.format(),
              child: Text(
                due.fromNow(),
                style: isDone
                    ? null
                    : Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.taskOverdueFG,
                        ),
              ),
            ),
            subtitle: const Text('Overdue'),
          ),
        );
      } else {
        // FIXME: HL today, tomorrow
        body.add(
          ListTile(
            key: dueDateField,
            dense: true,
            onTap: () async {
              await duePicker(context, due.dateTime);
            },
            subtitle: const Text('Due'),
            title: Text(
              due.fromNow(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      }
    }
    final description = task.description();
    if (description != null) {
      final formattedBody = description.formattedBody();
      if (formattedBody != null && formattedBody.isNotEmpty) {
        body.add(
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: RenderHtml(text: formattedBody),
          ),
        );
      } else {
        final str = description.body();
        if (str.isNotEmpty) {
          body.add(
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(str),
            ),
          );
        }
      }
    }

    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: InkWell(
                  key: isDone ? statusBtnDone : statusBtnNotDone,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Icon(
                      isDone
                          ? Atlas.check_circle_thin
                          : Icons.radio_button_off_outlined,
                      size: 48,
                    ),
                  ),
                  onTap: () async {
                    final updater = task.updateBuilder();
                    if (!isDone) {
                      updater.markDone();
                    } else {
                      updater.markUndone();
                    }
                    await updater.send();
                  },
                ),
                title: Wrap(
                  children: [
                    Text(
                      task.title(),
                      style: isDone
                          ? Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                fontWeight: FontWeight.w100,
                                color: AppTheme.brandColorScheme.neutral5,
                              )
                          : Theme.of(context).textTheme.headlineSmall!,
                    ),
                  ],
                ),
              ),
              ...body,
            ],
          ),
        ),
      ],
    );
  }
}

class TaskInfoSkeleton extends StatelessWidget {
  const TaskInfoSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(
                  Icons.radio_button_off_outlined,
                  size: 48,
                ),
              ),
              title: Wrap(
                children: [
                  Text(
                    'Loading a task with a lengthy name so we have something nice to show',
                    style: Theme.of(context).textTheme.headlineMedium!,
                  ),
                ],
              ),
            ),
            ListTile(
              dense: true,
              subtitle: const Text('Due'),
              title: Text(
                'today',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'This is a multiline description of the task with lengthy texts and stuff',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
