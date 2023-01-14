import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/widgets/OnboardingWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({Key? key, required this.controller})
      : super(key: key);
  final ToDoController controller;

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController teamInputController = TextEditingController();
  final TextEditingController taskInputController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  List<String> categories = ['Personal', 'Work', 'Red Team'];
  bool check = false;
  Offset? tapXY;
  RenderBox? overlay;

  @override
  void initState() {
    super.initState();
    widget.controller.setSelectedTeam('');
    widget.controller.taskNameCount.value = 30;
  }

  RelativeRect get relRectSize =>
      RelativeRect.fromSize(tapXY! & const Size(40, 40), overlay!.size);

  void getPosition(TapDownDetails detail) {
    tapXY = detail.globalPosition;
  }

  @override
  Widget build(BuildContext context) {
    overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: ToDoTheme.toDoDecoration,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).size.height * 0.12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'Create Task',
                  style: ToDoTheme.titleTextStyle,
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                height: 60,
                decoration: BoxDecoration(
                  color: ToDoTheme.textFieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x18E5E5E5), width: 0.5),
                ),
                child: TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                    border: InputBorder.none,
                    hintText: 'Task Title',
                    // hide default counter helper
                    counterText: '',
                    // pass the hint text parameter here
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  maxLength: 30,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Cannot be empty';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      widget.controller.updateWordCount(value.length),
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                  child: Text(
                    'Word Count: ${widget.controller.taskNameCount.value}',
                    style: ToDoTheme.textFieldCounterStyle,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                decoration: BoxDecoration(
                  color: ToDoTheme.textFieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0x18E5E5E5), width: 0.5),
                ),
                child: TextFormField(
                  controller: descriptionController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
                    border: InputBorder.none,
                    hintText: 'Task Description',
                    // pass the hint text parameter here
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  maxLines: 5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Obx(
                      () => InkWell(
                        onTap: () => _showPopupMenu(context),
                        onTapDown: widget.controller.taskNameCount.value < 30
                            ? getPosition
                            : null,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.06,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ToDoTheme.textFieldColor,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            widget.controller.selectedTeam.value.isNotEmpty
                                ? widget.controller.selectedTeam.value
                                : 'Select Team',
                            style: ToDoTheme.selectTeamTextStyle.copyWith(
                              color: widget.controller.taskNameCount.value < 30
                                  ? null
                                  : const Color(0xFF898A8D),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Transform.rotate(
                        angle: 90,
                        child: const Icon(
                          FlutterIcons.flow_branch_ent,
                          color: ToDoTheme.calendarColor,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Divider(
                color: ToDoTheme.dividerColor,
                endIndent: 10,
                indent: 10,
              ),
              Obx(
                () => Visibility(
                  visible: widget.controller.taskNameCount < 30,
                  child: Row(
                    children: <Widget>[
                      Visibility(
                        visible: taskInputController.text.isNotEmpty,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                check = !check;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: AppCommonTheme.transparentColor,
                              radius: 18,
                              child: Container(
                                height: 25,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: check
                                      ? ToDoTheme.activeCheckColor
                                      : ToDoTheme.inactiveCheckColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.grey,
                                  ),
                                ),
                                child: checkBuilder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: taskInputController,
                          cursorColor: ToDoTheme.primaryTextColor,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(left: 12, top: -2),
                            hintText: 'Input here the task',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            setState(() {
                              taskInputController.text = val;
                              taskInputController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(
                                  offset: taskInputController.text.length,
                                ),
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CustomOnbaordingButton(
                    onPressed: widget.controller.taskNameCount < 30
                        ? () async {
                            await widget.controller
                                .createToDoList(
                                  nameController.text,
                                  descriptionController.text,
                                )
                                .then(
                                  (value) => debugPrint('TASK Created :$value'),
                                );
                            Navigator.pop(context);
                          }
                        : null,
                    title: 'Create Task',
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget? checkBuilder() {
    if (!check) {
      return null;
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 10,
    );
  }

  void _showPopupMenu(BuildContext ctx) async {
    await showMenu<String>(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
      context: ctx,
      position: relRectSize,
      color: ToDoTheme.bottomSheetColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        PopupMenuItem(
          onTap: () => widget.controller.setSelectedTeam('No Team'),
          height: 24,
          child: const Text(
            'No Team',
            style: TextStyle(
              color: ToDoTheme.todayCalendarColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        for (String val in categories)
          PopupMenuItem(
            onTap: () => widget.controller.setSelectedTeam(val),
            height: 24,
            child: Text(
              val,
              style: ToDoTheme.selectTeamTextStyle,
            ),
          ),
        PopupMenuItem(
          //To prevent immediate pop up of context, use delay to show dialog.
          onTap: () => Future.delayed(
            const Duration(seconds: 0),
            () => _showTeamDialog(ctx),
          ),
          height: 24,
          child: const Text(
            '+ Create Team',
            style: TextStyle(
              color: ToDoTheme.todayCalendarColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
      elevation: 8,
    );
  }

  void _showTeamDialog(BuildContext ctx) async {
    await showDialog(
      context: ctx,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              insetPadding: EdgeInsets.zero,
              backgroundColor: ToDoTheme.backgroundGradientColor,
              title: const Text('Create new team'),
              titleTextStyle: ToDoTheme.listMemberTextStyle,
              contentPadding: const EdgeInsets.all(13),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: ToDoTheme.secondaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: teamInputController.text.isEmpty
                      ? null
                      : () {
                          if (formGlobalKey.currentState!.validate()) {
                            setState(() {
                              categories.add(teamInputController.text);
                            });
                            Navigator.pop(ctx);
                          }
                        },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: teamInputController.text.isNotEmpty
                          ? ToDoTheme.secondaryTextColor
                          : ToDoTheme.secondaryTextColor.withOpacity(0.45),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              ],
              content: Form(
                key: formGlobalKey,
                child: TextFormField(
                  controller: teamInputController,
                  maxLines: 5,
                  maxLength: 50,
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: ToDoTheme.bottomSheetColor,
                    hintText: 'Input here.',
                    helperStyle: ToDoTheme.infoAvatarTextStyle,
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: EdgeInsets.all(13),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                        style: BorderStyle.none,
                        width: 0,
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: ToDoTheme.primaryColor, width: 0),
                      borderRadius: BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                  ),
                  style: ToDoTheme.descriptionTextStyle,
                  onChanged: (val) {
                    setState(() {
                      teamInputController.text = val;
                      teamInputController.selection =
                          TextSelection.fromPosition(
                        TextPosition(
                          offset: teamInputController.text.length,
                        ),
                      );
                    });
                  },
                  validator: (val) {
                    if (categories.contains(val)) {
                      return 'Team name has to be unique';
                    }
                    return null;
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
