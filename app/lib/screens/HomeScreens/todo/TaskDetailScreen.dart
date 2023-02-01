import 'dart:io';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoComment.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio/screens/HomeScreens/todo/TaskAssignScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ToDoTaskDetailScreen extends StatelessWidget {
  const ToDoTaskDetailScreen({
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
      backgroundColor: ToDoTheme.backgroundGradientColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ToDoTheme.secondaryColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          color: ToDoTheme.primaryTextColor,
        ),
        title: Obx(
          () => Text(
            cntrl.todos[listIndex].tasks[index].name,
            style: ToDoTheme.listTitleTextStyle,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showMoreBottomSheet(context),
            icon: const Icon(Icons.more_horiz),
            color: ToDoTheme.primaryTextColor,
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
            const _DueDateWidget(),
            const _DividerWidget(),
            const _AddFileWidget(),
            const _DividerWidget(),
            _DiscussionWidget(cntrl.todos[listIndex].tasks[index]),
            const _DividerWidget(),
            const _SubscribersWidget(),
            const _DividerWidget(),
            Obx(
              () => Visibility(
                visible: cntrl.commentInput.value,
                replacement: const _LastUpdatedWidget(),
                child: _CommentInput(cntrl.todos[listIndex].tasks[index]),
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
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.link,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.comments_disabled_outlined,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.delete_outline,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.access_time,
        color: ToDoTheme.primaryTextColor,
      ),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
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
                    style: ToDoTheme.listMemberTextStyle,
                  ),
                ),
              ),
            ),
            Container(
              height: 60,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: ToDoTheme.primaryTextColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Share this ToDo',
                  style: ToDoTheme.listMemberTextStyle,
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
        color: ToDoTheme.dividerColor,
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
          Flexible(
            child: InkWell(
              onTap: () async => await controller
                  .updateToDoTask(task, list, null, null)
                  .then((res) {
                debugPrint('TOGGLE CHECK');
              }),
              child: CircleAvatar(
                backgroundColor: AppCommonTheme.transparentColor,
                radius: 18,
                child: Container(
                  height: 25,
                  width: 25,
                  decoration: BoxDecoration(
                    color: (task.progressPercent >= 100)
                        ? ToDoTheme.activeCheckColor
                        : ToDoTheme.inactiveCheckColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1.5,
                      color: ToDoTheme.floatingABColor,
                    ),
                  ),
                  child: _CheckWidget(task: task),
                ),
              ),
            ),
          ),
          GetBuilder<ToDoController>(
            id: 'task-name',
            builder: (_) {
              return Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    style: ToDoTheme.taskTitleTextStyle.copyWith(
                      decoration: (task.progressPercent >= 100)
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    cursorColor: ToDoTheme.primaryTextColor,
                    onChanged: (val) =>
                        controller.updateNameInput(_nameController, val),
                    onEditingComplete: () async =>
                        await controller.updateToDoTask(
                      task,
                      list,
                      _nameController.text.trim(),
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
      return const SizedBox.shrink();
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 14,
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
                return TaskAssignScreen();
              },
            ),
          ),
          child: const Text(
            '+ Assign',
            style: ToDoTheme.addTaskTextStyle,
          ),
        )
      ],
    );
  }
}

class _DueDateWidget extends StatelessWidget {
  const _DueDateWidget();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showBottomSheet(context, 'Add Due Date'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/calendar-2.svg',
              width: 18,
              height: 18,
              color: ToDoTheme.calendarColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Add Due Date',
                style: ToDoTheme.taskTitleTextStyle.copyWith(
                  color: ToDoTheme.calendarColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showBottomSheet(BuildContext context, String title) {
    List<String> options = [
      'Later Today',
      'Tomorrow',
      'Next Week',
      'Pick a Date & Time'
    ];
    List<String> optionIcons = [
      'assets/images/clock.svg',
      'assets/images/calendar-2.svg',
      'assets/images/calendar.svg',
      'assets/images/calendar-tick.svg'
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: false,
      builder: (BuildContext context) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Remove',
                  style: ToDoTheme.taskSubtitleTextStyle.copyWith(
                    color: ToDoTheme.removeColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(title, style: ToDoTheme.taskTitleTextStyle),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Done',
                  style: ToDoTheme.taskSubtitleTextStyle.copyWith(
                    color: ToDoTheme.floatingABColor,
                  ),
                ),
              ),
            ),
            const Divider(
              color: ToDoTheme.bottomSheetDividerColor,
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
                (index) => InkWell(
                  onTap: () => showNotYetImplementedMsg(
                    context,
                    '${options[index]} is not yet implemented',
                  ),
                  child: ListTile(
                    leading: SvgPicture.asset(
                      optionIcons[index],
                      color: index == options.length - 1
                          ? ToDoTheme.floatingABColor
                          : Colors.white,
                    ),
                    title: Text(
                      options[index],
                      style: index == options.length - 1
                          ? ToDoTheme.listMemberTextStyle
                              .copyWith(color: ToDoTheme.floatingABColor)
                          : ToDoTheme.listMemberTextStyle,
                    ),
                    trailing: index == options.length - 1
                        ? const Icon(
                            FlutterIcons.chevron_right_ent,
                            color: ToDoTheme.floatingABColor,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
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
            SvgPicture.asset(
              'assets/images/quill_attachment.svg',
              width: 18,
              height: 18,
              color: ToDoTheme.calendarColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Add File',
                style: ToDoTheme.taskTitleTextStyle.copyWith(
                  color: ToDoTheme.calendarColor,
                  fontWeight: FontWeight.w600,
                ),
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
        data: const CupertinoThemeData(
          scaffoldBackgroundColor: ToDoTheme.bottomSheetColor,
        ),
        child: CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    FlutterIcons.camera_outline_mco,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Take a Photo',
                          style: ToDoTheme.listTitleTextStyle,
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
                    FlutterIcons.md_photos_ion,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Choose from Photos',
                          style: ToDoTheme.listTitleTextStyle,
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
                    FlutterIcons.file_document_outline_mco,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Choose from Files',
                          style: ToDoTheme.listTitleTextStyle,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text(
              'Cancel',
              style: ToDoTheme.listTitleTextStyle,
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
  const _DiscussionWidget(this.task);
  final ToDoTask task;

  @override
  Widget build(BuildContext context) {
    final ToDoController controller = Get.find<ToDoController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  const Icon(
                    FlutterIcons.message1_ant,
                    color: ToDoTheme.calendarColor,
                    size: 18,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Discussion',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        color: ToDoTheme.calendarColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Icon(
                FlutterIcons.dot_single_ent,
                color: Colors.grey,
              ),

              // TODO: fix comments count.
              GetBuilder<ToDoController>(
                id: 'discussion',
                builder: (_) {
                  return Text(
                    '${task.commentsManager.commentsCount()}',
                    style: ToDoTheme.listMemberTextStyle,
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
                    style: ToDoTheme.taskTitleTextStyle.copyWith(
                      color: AppCommonTheme.secondaryColor,
                    ),
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
                        child: CircularProgressIndicator(
                          color: AppCommonTheme.primaryColor,
                        ),
                      );
                    } else {
                      if (snapshot.hasData) {
                        if (snapshot.data!.isNotEmpty) {
                          List<ToDoComment> comments =
                              snapshot.data!.reversed.toList();
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 5,
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
                                style: ToDoTheme.taskListTextStyle,
                              ),
                              subtitle: Text(
                                comments[index].text ?? '',
                                style: ToDoTheme.activeTasksTextStyle,
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
                                      FlutterIcons.dots_three_horizontal_ent,
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
                                    style: ToDoTheme.todayCalendarTextStyle
                                        .copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            separatorBuilder: (context, index) => const Divider(
                              color: ToDoTheme.dividerColor,
                            ),
                          );
                        } else {
                          const SizedBox.shrink();
                        }
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to fetch due to ${snapshot.error.toString()} ',
                            style: ToDoTheme.listMemberTextStyle,
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
    );
  }

  void showCommentBottomSheet(BuildContext context) {
    List<String> options = ['Save', 'Copy Link', 'Share', 'Report'];
    List<Icon> optionIcons = [
      const Icon(
        Icons.bookmark_border,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.link,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.file_upload_outlined,
        color: ToDoTheme.primaryTextColor,
      ),
      const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
      ),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
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
                  color: ToDoTheme.secondaryCardColor,
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
                      style: index == options.length - 1
                          ? ToDoTheme.listMemberTextStyle
                              .copyWith(color: Colors.red)
                          : ToDoTheme.listMemberTextStyle,
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
              style: ToDoTheme.taskTitleTextStyle.copyWith(
                color: ToDoTheme.calendarColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'No one will be notified when someone comments on this to-do list',
            style: ToDoTheme.taskTitleTextStyle.copyWith(
              color: ToDoTheme.calendarColor,
              fontSize: 13,
            ),
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
                style: ToDoTheme.taskTitleTextStyle.copyWith(
                  color: ToDoTheme.calendarColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'You are not subscribed',
              style: ToDoTheme.taskTitleTextStyle.copyWith(
                color: ToDoTheme.calendarColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            "You won't be notified when comments are posted",
            style: ToDoTheme.taskTitleTextStyle.copyWith(
              color: ToDoTheme.calendarColor,
              fontSize: 13,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(100)),
              border: Border.all(color: Colors.white),
            ),
            child: Text(
              'Subscriber me',
              style: ToDoTheme.taskTitleTextStyle.copyWith(
                color: ToDoTheme.calendarColor,
                fontSize: 13,
              ),
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
          style: ToDoTheme.activeTasksTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _CommentInput extends StatefulWidget {
  const _CommentInput(this.task);
  final ToDoTask task;
  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final ToDoController controller = Get.find<ToDoController>();
  bool emojiShowing = false;
  final TextEditingController _inputController = TextEditingController();
  void onEmojiSelected(Emoji emoji) {
    _inputController
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
  }

  void onBackspacePressed() {
    _inputController
      ..text = _inputController.text.characters.skipLast(1).toString()
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _inputController.text.length),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ToDoTheme.textFieldColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CustomAvatar(
                    uniqueKey: controller.client.account().userId(),
                    radius: 18,
                    isGroup: false,
                    avatar: controller.client.account().avatar(),
                    stringName: simplifyUserId(
                          controller.client.account().userId(),
                        ) ??
                        '',
                    cacheHeight: 120,
                    cacheWidth: 120,
                  ),
                ),
                GetBuilder<ToDoController>(
                  id: 'comment-input',
                  builder: (cntrl) {
                    return Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: AppCommonTheme.textFieldColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextField(
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                cursorColor: Colors.grey,
                                controller: _inputController,
                                decoration: const InputDecoration(
                                  hintText: 'New Message',
                                  hintStyle: TextStyle(
                                    color: Colors.grey,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onChanged: (val) => cntrl.updateCommentInput(
                                  _inputController,
                                  val,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  emojiShowing = !emojiShowing;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GetBuilder<ToDoController>(
                  id: 'comment-input',
                  builder: (cntrl) {
                    return Visibility(
                      visible: _inputController.text.trim().isNotEmpty,
                      child: IconButton(
                        onPressed: () async => await cntrl
                            .sendComment(
                          widget.task.commentsManager.commentDraft(),
                          _inputController.text.trim(),
                        )
                            .then((res) {
                          cntrl.updateCommentInput(_inputController, '');
                          debugPrint('Comment id: $res');
                        }),
                        icon: const Icon(Icons.send, color: Colors.pink),
                      ),
                    );
                  },
                ),
              ],
            ),
            Offstage(
              offstage: !emojiShowing,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    onEmojiSelected(emoji);
                  },
                  onBackspacePressed: onBackspacePressed,
                  config: Config(
                    columns: 7,
                    emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    initCategory: Category.RECENT,
                    bgColor: Colors.white,
                    indicatorColor: Colors.blue,
                    iconColor: Colors.grey,
                    iconColorSelected: Colors.blue,
                    backspaceColor: Colors.blue,
                    skinToneDialogBgColor: Colors.white,
                    skinToneIndicatorColor: Colors.grey,
                    enableSkinTones: true,
                    showRecentsTab: true,
                    recentsLimit: 28,
                    noRecents: const Text(
                      'No Recents',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black26,
                      ),
                    ),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: const CategoryIcons(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
