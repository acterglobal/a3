import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/utils.dart';
import 'package:effektio/features/todo/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoComment.dart';
import 'package:effektio/features/todo/widgets/comment_input.dart';
import 'package:effektio/common/widgets/custom_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';

class TaskCommentsPage extends StatefulWidget {
  const TaskCommentsPage({
    Key? key,
    required this.listIndex,
    required this.index,
  }) : super(key: key);
  final int listIndex;
  final int index;

  @override
  State<TaskCommentsPage> createState() => _TaskCommentsPageState();
}

class _TaskCommentsPageState extends State<TaskCommentsPage> {
  late Future<List<ToDoComment>> _comments;
  final ToDoController cntrl = Get.find<ToDoController>();

  @override
  void initState() {
    super.initState();
    _comments =
        cntrl.getComments(cntrl.todos[widget.listIndex].tasks[widget.index]);
  }

  void onSendPressed() {
    setState(() {
      _comments =
          cntrl.getComments(cntrl.todos[widget.listIndex].tasks[widget.index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColorLight,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'Comments',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Visibility(
              visible: cntrl
                  .todos[widget.listIndex].tasks[widget.index].commentsManager
                  .hasComments(),
              replacement: Center(
                heightFactor: MediaQuery.of(context).size.height * 0.03,
                child: const Text(
                  'Be the first to comment!',
                  style: ToDoTheme.listTitleTextStyle,
                ),
              ),
              child: FutureBuilder<List<ToDoComment>>(
                future: _comments,
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
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => ListTile(
                            leading: CustomAvatar(
                              uniqueKey: snapshot.data![index].userId,
                              radius: 18,
                              isGroup: false,
                              stringName: simplifyUserId(
                                snapshot.data![index].userId,
                              )!,
                            ),
                            title: Text(
                              simplifyUserId(
                                    snapshot.data![index].userId,
                                  ) ??
                                  'No Name',
                              style: ToDoTheme.taskTitleTextStyle,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  snapshot.data![index].text ?? '',
                                  style: ToDoTheme.activeTasksTextStyle,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 8, 8, 8),
                                  child: Text(
                                    timeAgo(snapshot.data![index].time),
                                    style: ToDoTheme.todayCalendarTextStyle
                                        .copyWith(fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            trailing: InkWell(
                              onTap: () => showCommentBottomSheet(context),
                              child: const Icon(
                                FlutterIcons.dots_three_horizontal_ent,
                                color: Colors.white,
                              ),
                            ),
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
            ),
          ),
          CommentInput(
            cntrl.todos[widget.listIndex].tasks[widget.index],
            onSendPressed,
          ),
        ],
      ),
    );
  }

  String timeAgo(DateTime d) {
    Duration diff = DateTime.now().difference(d);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}yr';
    }

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mon';
    }
    if (diff.inDays > 7) {
      return '${(diff.inDays / 7).floor()}w';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'just now';
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
