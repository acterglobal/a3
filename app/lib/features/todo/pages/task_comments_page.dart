import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/ToDoComment.dart';
import 'package:acter/features/todo/widgets/comment_input.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
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
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Atlas.arrow_left_circle,
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
                ),
              ),
              child: FutureBuilder<List<ToDoComment>>(
                future: _comments,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
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
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  snapshot.data![index].text ?? '',
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 8, 8, 8),
                                  child: Text(
                                    timeAgo(snapshot.data![index].time),
                                  ),
                                ),
                              ],
                            ),
                            trailing: InkWell(
                              onTap: () => showCommentBottomSheet(context),
                              child: const Icon(
                                Atlas.dots_horizontal,
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
      ),
      const Icon(
        Icons.link,
      ),
      const Icon(
        Icons.file_upload_outlined,
      ),
      const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
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
