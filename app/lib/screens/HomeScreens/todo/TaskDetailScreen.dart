import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio/screens/HomeScreens/todo/TaskAssignScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoTaskDetailScreen extends StatelessWidget {
  const ToDoTaskDetailScreen({
    Key? key,
    required this.task,
    required this.list,
    required this.controller,
  }) : super(key: key);
  final ToDoTask task;
  final ToDoList list;
  final ToDoController controller;

  @override
  Widget build(BuildContext context) {
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
        title: Text(task.name, style: ToDoTheme.listTitleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => showMoreBottomSheet(context),
            icon: const Icon(Icons.more_horiz),
            color: ToDoTheme.primaryTextColor,
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameWidget(task, list, controller),
              const _DividerWidget(),
              const _AssignWidget(),
              const _DividerWidget(),
              const _DueDateWidget(),
              const _DividerWidget(),
              const _AddFileWidget(),
              const _DividerWidget(),
              const _DiscussionWidget(),
              const _DividerWidget(),
              const _SubscribersWidget(),
              const _DividerWidget(),
              const _LastUpdatedWidget(),
            ],
          ),
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

  Widget infoAvatarBuilder(int count) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: ToDoTheme.infoAvatarColor,
      child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
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
  const _NameWidget(this.task, this.list, this.controller);
  final ToDoTask task;
  final ToDoList list;
  final ToDoController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: InkWell(
              onTap: () async => await controller
                  .markToDoTask(task, list)
                  .then((res) => debugPrint('TOGGLE CHECK')),
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
                  child: checkBuilder(),
                ),
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                task.name,
                style: ToDoTheme.taskTitleTextStyle.copyWith(
                  decoration: (task.progressPercent >= 100)
                      ? TextDecoration.lineThrough
                      : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? checkBuilder() {
    if ((task.progressPercent < 100)) {
      return null;
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
  const _DiscussionWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          InkWell(
            onTap: () {
              showNotYetImplementedMsg(
                context,
                'Writing message is not implemented yet',
              );
            },
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
