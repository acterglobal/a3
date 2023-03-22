import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoComment.dart';
import 'package:acter/models/ToDoList.dart';
import 'package:acter/models/ToDoTask.dart';
import 'package:acter/features/todo/pages/task_assign_page.dart';
import 'package:acter/features/todo/pages/task_comments_page.dart';
import 'package:acter/features/todo/widgets/comment_input.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({
    Key? key,
    required this.index,
    required this.listIndex,
  }) : super(key: key);
  final int index;
  final int listIndex;

  @override
  Widget build(BuildContext context) {
    final ToDoController cntrl = Get.find<ToDoController>();
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Atlas.xmark_circle),
        ),
        title: Obx(
          () => Text(
            cntrl.todos[listIndex].tasks[index].name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showMoreBottomSheet(context),
            icon: const Icon(Atlas.dots_horizontal),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => _NameWidget(
                cntrl.todos[listIndex].tasks[index],
                cntrl.todos[listIndex],
              ),
            ),
            const _DividerWidget(),
            const _AssignWidget(),
            const _DividerWidget(),
            Obx(
              () => _DueDateWidget(
                cntrl.todos[listIndex].tasks[index],
                cntrl.todos[listIndex],
              ),
            ),
            const _DividerWidget(),
            const _AddFileWidget(),
            const _DividerWidget(),
            _DiscussionWidget(
              cntrl.todos[listIndex].tasks[index],
              listIndex,
              index,
            ),
            const _DividerWidget(),
            const _SubscribersWidget(),
            const _DividerWidget(),
            Obx(
              () => Visibility(
                visible: cntrl.commentInput.value,
                replacement: const _LastUpdatedWidget(),
                child: CommentInput(cntrl.todos[listIndex].tasks[index], null),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showMoreBottomSheet(BuildContext context) {
    List<String> options = [
      'BookMark',
      'Copy Link',
      'Close Comment',
      'Delete',
      'View change log'
    ];
    List<Icon> optionIcons = [
      const Icon(
        Icons.bookmark_border,
      ),
      const Icon(
        Icons.link,
      ),
      const Icon(
        Icons.comments_disabled_outlined,
      ),
      const Icon(
        Icons.delete_outline,
      ),
      const Icon(
        Icons.access_time,
      ),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              children: List.generate(
                options.length,
                (index) => ListTile(
                  leading: optionIcons[index],
                  title: Text(
                    options[index],
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
            Container(
              height: 60,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Share this ToDo',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class _DividerWidget extends StatelessWidget {
  const _DividerWidget();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        thickness: 1,
        indent: 10,
        endIndent: 10,
      ),
    );
  }
}

class _NameWidget extends StatelessWidget {
  const _NameWidget(this.task, this.list);
  final ToDoTask task;
  final ToDoList list;
  @override
  Widget build(BuildContext context) {
    final ToDoController controller = Get.find<ToDoController>();
    final TextEditingController _nameController =
        TextEditingController(text: task.name);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () async => await controller
                .updateToDoTask(task, list, null, null, null)
                .then((res) {
              debugPrint('Update eventId: $res');
            }),
            child: _CheckWidget(task: task),
          ),
          GetBuilder<ToDoController>(
            id: 'task-name',
            builder: (_) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onChanged: (val) =>
                        controller.updateNameInput(_nameController, val),
                    onEditingComplete: () async =>
                        await controller.updateToDoTask(
                      task,
                      list,
                      _nameController.text.trim(),
                      null,
                      task.progressPercent,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CheckWidget extends StatelessWidget {
  const _CheckWidget({
    required this.task,
  });

  final ToDoTask task;

  @override
  Widget build(BuildContext context) {
    if ((task.progressPercent < 100)) {
      return Icon(
        Icons.done_outlined,
        size: 14,
        color: Theme.of(context).colorScheme.tertiary,
      );
    }
    return Icon(
      Icons.done_outlined,
      size: 14,
      color: Theme.of(context).colorScheme.tertiary,
    );
  }
}

class _AssignWidget extends StatelessWidget {
  const _AssignWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(flex: 2),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) {
                return TaskAssignPage();
              },
            ),
          ),
          child: Text(
            '+ Assign',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        )
      ],
    );
  }
}

class _DueDateWidget extends StatelessWidget {
  const _DueDateWidget(this.task, this.list);
  final ToDoTask task;
  final ToDoList list;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showBottomSheet(context, task),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Row(
          children: <Widget>[
            const Icon(Atlas.calendar),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: task.due != null
                  ? Text(
                      'Due ${DateFormat('E, d MMM').format(task.due!.toUtc())}',
                      style: Theme.of(context).textTheme.labelSmall,
                    )
                  : Text(
                      'Add Due Date',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void showBottomSheet(BuildContext context, ToDoTask task) {
    DateTime? _selectedDate = task.due;
    int? tappedIdx;
    ToDoController controller = Get.find<ToDoController>();
    List<String> options = [
      'Later Today',
      'Tomorrow',
      'Next Week',
      'Pick a Date & Time'
    ];
    const List<Icon> optionIcons = [
      Icon(Atlas.clock),
      Icon(Atlas.calendar),
      Icon(Atlas.calendar),
      Icon(Atlas.calendar_schedule)
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void _showDatePicker(BuildContext ctx) async {
              await showDatePicker(
                context: ctx,
                initialDatePickerMode: DatePickerMode.day,
                initialEntryMode: DatePickerEntryMode.calendarOnly,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                currentDate: DateTime.now(),
                lastDate: DateTime(DateTime.now().year + 10),
                confirmText: 'Done',
                cancelText: 'Cancel',
                builder: (BuildContext ctx, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(),
                    child: child!,
                  );
                },
              ).then((_pickedDate) {
                if (_pickedDate != null) {
                  setState(() {
                    _selectedDate = _pickedDate;
                  });
                } else {
                  Navigator.pop(context);
                }
              });
            }

            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextButton(
                    onPressed: () async {
                      await controller.updateToDoTask(
                        task,
                        list,
                        null,
                        null,
                        task.progressPercent,
                      );
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Remove',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _selectedDate != null ? 'Change Due Date' : 'Add Due Date',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextButton(
                    onPressed: () async {
                      await controller.updateToDoTask(
                        task,
                        list,
                        null,
                        _selectedDate,
                        task.progressPercent,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                    ),
                  ),
                ),
                const Divider(
                  height: 0,
                  thickness: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(10),
                  children: List.generate(
                    options.length,
                    (index) => ListTile(
                      onTap: () {
                        final now = DateTime.now();
                        setState(() {
                          tappedIdx = index;
                          switch (index) {
                            case 0:
                              _selectedDate = now;
                              break;
                            case 1:
                              _selectedDate =
                                  DateTime(now.year, now.month, now.day + 1);
                              break;
                            case 2:
                              DateTime nextWeek =
                                  now.add(const Duration(days: 7));
                              int weekDay = nextWeek.weekday;
                              if (weekDay == 7) {
                                _selectedDate = nextWeek;
                              } else {
                                _selectedDate = nextWeek
                                    .subtract(Duration(days: weekDay - 1));
                              }
                              break;
                            case 3:
                              Future.delayed(
                                const Duration(seconds: 0),
                                () => _showDatePicker(context),
                              );
                              break;
                          }
                        });
                      },
                      tileColor: Colors.transparent,
                      selected: tappedIdx != null && tappedIdx == index,
                      leading: optionIcons[index],
                      title: Text(
                        options[index],
                      ),
                      trailing: index == options.length - 1
                          ? const Icon(
                              Atlas.arrow_right_circle,
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AddFileWidget extends StatelessWidget {
  const _AddFileWidget();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showActionSheet(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            const Icon(Atlas.pen),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Add File',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(),
        child: CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    Atlas.camera_photo,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Take a Photo',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    Atlas.photo_camera,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Choose from Photos',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    Atlas.file,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Choose from Files',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }
}

class _DiscussionWidget extends StatelessWidget {
  const _DiscussionWidget(this.task, this.listIndex, this.index);
  final ToDoTask task;
  final int listIndex;
  final int index;
  @override
  Widget build(BuildContext context) {
    final ToDoController controller = Get.find<ToDoController>();
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TaskCommentsPage(listIndex: listIndex, index: index),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(
                      Atlas.message,
                      size: 18,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Discussion',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.grey,
                ),

                // TODO: fix comments count.
                GetBuilder<ToDoController>(
                  id: 'discussion',
                  builder: (_) {
                    return Text(
                      '${task.commentsManager.commentsCount()}',
                      style: Theme.of(context).textTheme.labelSmall,
                    );
                  },
                ),
                const Spacer(),
                InkWell(
                  onTap: () => controller.toggleCommentInput(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Write message',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
            GetBuilder<ToDoController>(
              id: 'discussion',
              builder: (_) {
                return Visibility(
                  visible: task.commentsManager.hasComments(),
                  child: FutureBuilder<List<ToDoComment>>(
                    future: controller.getComments(task),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else {
                        if (snapshot.hasData) {
                          if (snapshot.data!.isNotEmpty) {
                            List<ToDoComment> comments =
                                snapshot.data!.reversed.toList();
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount:
                                  comments.length > 5 ? 5 : comments.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: CustomAvatar(
                                  uniqueKey: comments[index].userId,
                                  radius: 18,
                                  isGroup: false,
                                  stringName: simplifyUserId(
                                    comments[index].userId,
                                  )!,
                                ),
                                title: Text(
                                  simplifyUserId(comments[index].userId) ??
                                      'No Name',
                                ),
                                subtitle: Text(
                                  comments[index].text ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () =>
                                          showCommentBottomSheet(context),
                                      child: const Icon(
                                        Atlas.dots_horizontal,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      comments[index].time.isToday()
                                          ? 'Today'
                                          : comments[index].time.isYesterday()
                                              ? 'Yesterday'
                                              : DateFormat('H:mm E, d MMM')
                                                  .format(comments[index].time),
                                    ),
                                  ],
                                ),
                              ),
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                            );
                          } else {
                            const SizedBox.shrink();
                          }
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to fetch due to ${snapshot.error.toString()} ',
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void showCommentBottomSheet(BuildContext context) {
    List<String> options = ['Save', 'Copy Link', 'Share', 'Report'];
    List<Icon> optionIcons = [
      const Icon(
        Icons.bookmark_border,
      ),
      const Icon(
        Icons.link,
      ),
      const Icon(
        Icons.file_upload_outlined,
      ),
      const Icon(
        Icons.warning_amber_rounded,
      ),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            alignment: WrapAlignment.spaceEvenly,
            children: List.generate(
              options.length,
              (index) => Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    optionIcons[index],
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      options[index],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SubscribersWidget extends StatelessWidget {
  const _SubscribersWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'Subscribers',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            'No one will be notified when someone comments on this to-do list',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          InkWell(
            onTap: () => showNotYetImplementedMsg(
              context,
              'Subscriber Screen not yet implemented',
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(100)),
                border: Border.all(color: Colors.white),
              ),
              child: Text(
                'Add/remove people',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'You are not subscribed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            "You won't be notified when comments are posted",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              'Subscribe me',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedWidget extends StatelessWidget {
  const _LastUpdatedWidget();
  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: Text(
          'Last Update ???',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
