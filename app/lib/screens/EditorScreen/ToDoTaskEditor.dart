import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class ToDoTaskEditor extends StatefulWidget {
  const ToDoTaskEditor({Key? key, required this.item, required this.avatars})
      : super(key: key);
  final ToDoTaskItem item;
  final List<ImageProvider<Object>> avatars;
  @override
  State<ToDoTaskEditor> createState() => _ToDoTaskEditorState();
}

class _ToDoTaskEditorState extends State<ToDoTaskEditor> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.left,
  );

  @override
  void initState() {
    super.initState();
    notesController.text = widget.item.notes ?? 'Add Notes';
    subtitleController.text = widget.item.subtitle;
  }

  @override
  void dispose() {
    super.dispose();
    notesController.dispose();
    subtitleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToDoTheme.backgroundGradientColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ToDoTheme.secondaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ToDoTheme.primaryTextColor,
        ),
        title: Text(widget.item.title, style: ToDoTheme.listTitleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
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
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(
                      color: ToDoTheme.calendarColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  GetBuilder<ToDoController>(
                    id: 'subtitle',
                    builder: (ToDoController controller) {
                      return Container(
                        margin: const EdgeInsets.only(left: 10, top: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.09,
                        child: TextFormField(
                          onFieldSubmitted: (val) {
                            subtitleController.text = val;
                            controller.updateNotes(
                              widget.item,
                              subtitleController,
                            );
                          },
                          maxLines: null,
                          controller: subtitleController,
                          style: ToDoTheme.subtitleTextStyle,
                          cursorColor: ToDoTheme.primaryTextColor,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 3),
                            border: InputBorder.none,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: AvatarStack(
                        borderWidth: 0,
                        settings: settings,
                        avatars: widget.avatars,
                        infoWidgetBuilder: _infoAvatar,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '+ Assign',
                      style: ToDoTheme.addTaskTextStyle,
                    ),
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/images/notification.svg',
                      width: 18,
                      height: 18,
                      color: ToDoTheme.calendarColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Remind Me',
                        style: ToDoTheme.calendarTextStyle
                            .copyWith(color: ToDoTheme.calendarColor),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
                        style: ToDoTheme.calendarTextStyle
                            .copyWith(color: ToDoTheme.calendarColor),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      'assets/images/repeat.svg',
                      width: 18,
                      height: 18,
                      color: ToDoTheme.calendarColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Repeat',
                        style: ToDoTheme.calendarTextStyle
                            .copyWith(color: ToDoTheme.calendarColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              GetBuilder<ToDoController>(
                id: 'notes',
                builder: (ToDoController controller) {
                  return SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.25,
                    child: TextFormField(
                      onFieldSubmitted: (val) {
                        notesController.text = val;
                        controller.updateNotes(widget.item, notesController);
                      },
                      controller: notesController,
                      style: ToDoTheme.taskTitleTextStyle
                          .copyWith(fontWeight: FontWeight.w500),
                      cursorColor: ToDoTheme.primaryTextColor,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              const SizedBox(
                height: 30,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoAvatar(int count) => CircleAvatar(
        radius: 28,
        backgroundColor: ToDoTheme.infoAvatarColor,
        child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
      );
}
