import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/Team.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';

class CreateTodoPage extends StatefulWidget {
  const CreateTodoPage({Key? key, required this.controller}) : super(key: key);
  final ToDoController controller;

  @override
  State<CreateTodoPage> createState() => _CreateTodoPageState();
}

class _CreateTodoPageState extends State<CreateTodoPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController taskInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.taskNameCount.value = 30;
    widget.controller.maxLength.value = double.maxFinite.toInt();
    widget.controller.setSelectedTeam(null);
  }

  @override
  Widget build(BuildContext context) {
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
      body: Container(
        decoration: ToDoTheme.toDoDecoration,
        height: MediaQuery.of(context).size.height -
            MediaQuery.of(context).size.height * 0.12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TitleWidget(),
            _NameInputWidget(
              nameController: nameController,
              controller: widget.controller,
            ),
            _WordCountWidget(controller: widget.controller),
            _DescriptionInputWidget(
              descriptionController: descriptionController,
            ),
            _SelectTeamWidget(
              controller: widget.controller,
              nameController: nameController,
            ),
            const _Divider(),
            const Spacer(),
            _CreateBtnWidget(
              controller: widget.controller,
              nameController: nameController,
              descriptionController: descriptionController,
            ),
          ],
        ),
      ),
    );
  }

  Widget? checkBuilder(bool check) {
    if (!check) {
      return null;
    }
    return const Icon(
      Icons.done_outlined,
      color: ToDoTheme.inactiveCheckColor,
      size: 10,
    );
  }
}

class _SelectTeamWidget extends StatefulWidget {
  const _SelectTeamWidget({
    required this.controller,
    required this.nameController,
  });
  final ToDoController controller;
  final TextEditingController nameController;

  @override
  State<_SelectTeamWidget> createState() => _SelectTeamWidgetState();
}

class _SelectTeamWidgetState extends State<_SelectTeamWidget> {
  final TextEditingController teamInputController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  RenderBox? overlay;
  Offset? tapXY;
  bool disableBtn = false;

  RelativeRect get relRectSize =>
      RelativeRect.fromSize(tapXY! & const Size(40, 40), overlay!.size);

  void getPosition(TapDownDetails detail) {
    tapXY = detail.globalPosition;
  }

  @override
  Widget build(BuildContext context) {
    overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          GetBuilder<ToDoController>(
            id: 'teams',
            builder: (_) {
              return InkWell(
                onTap: () => widget.nameController.text.trim().isNotEmpty
                    ? _showPopupMenu(context)
                    : null,
                onTapDown: widget.nameController.text.trim().isNotEmpty
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
                    widget.controller.selectedTeam != null
                        ? widget.controller.selectedTeam!.name!
                        : 'Select Team',
                    style: ToDoTheme.selectTeamTextStyle.copyWith(
                      color: widget.nameController.text.trim().isNotEmpty
                          ? null
                          : const Color(0xFF898A8D),
                    ),
                  ),
                ),
              );
            },
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
    );
  }

  void _showPopupMenu(BuildContext ctx) async {
    final List<Team> teams = await widget.controller.getTeams();
    showMenu(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.3),
      context: ctx,
      position: relRectSize,
      color: ToDoTheme.bottomSheetColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      items: [
        for (var team in teams)
          PopupMenuItem(
            onTap: () => widget.controller.setSelectedTeam(team),
            height: 24,
            child: Text(
              team.name!,
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
                  onPressed: (!disableBtn && teamInputController.text.isEmpty)
                      ? null
                      : () async {
                          if (formGlobalKey.currentState!.validate()) {
                            setState(() {
                              disableBtn = true;
                            });
                            await widget.controller
                                .createTeam(teamInputController.text);
                            setState(() {
                              disableBtn = false;
                            });
                            Navigator.pop(ctx);
                          }
                        },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color:
                          (!disableBtn && teamInputController.text.isNotEmpty)
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CreateBtnWidget extends StatelessWidget {
  const _CreateBtnWidget({
    required this.controller,
    required this.nameController,
    required this.descriptionController,
  });
  final ToDoController controller;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) => Obx(
        () => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: controller.isLoading.isTrue
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppCommonTheme.primaryColor,
                  ),
                )
              : CustomButton(
                  onPressed: (controller.taskNameCount < 30 &&
                          nameController.text.trim().isNotEmpty)
                      ? () async {
                          controller.isLoading.value = true;
                          await controller
                              .createToDoList(
                                controller.selectedTeam!.id,
                                nameController.text.trim(),
                                descriptionController.text.trim(),
                              )
                              .then((res) => debugPrint('ToDo CREATED: $res'));
                          controller.isLoading.value = false;
                          Navigator.pop(context);
                        }
                      : null,
                  title: 'Create',
                ),
        ),
      );
}

class _DescriptionInputWidget extends StatelessWidget {
  const _DescriptionInputWidget({
    required this.descriptionController,
  });

  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          color: ToDoTheme.textFieldColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x18E5E5E5), width: 0.5),
        ),
        child: TextFormField(
          controller: descriptionController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
            border: InputBorder.none,
            hintText: 'List Description',
            // pass the hint text parameter here
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          maxLines: 5,
        ),
      );
}

class _WordCountWidget extends StatelessWidget {
  const _WordCountWidget({
    required this.controller,
  });

  final ToDoController controller;
  @override
  Widget build(BuildContext context) => Obx(
        () => Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
          child: Text(
            'Word Count: ${controller.taskNameCount.value}',
            style: ToDoTheme.textFieldCounterStyle,
          ),
        ),
      );
}

class _NameInputWidget extends StatelessWidget {
  const _NameInputWidget({
    required this.nameController,
    required this.controller,
  });

  final TextEditingController nameController;
  final ToDoController controller;
  @override
  Widget build(BuildContext context) => Obx(
        () => Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          height: 60,
          decoration: BoxDecoration(
            color: ToDoTheme.textFieldColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x18E5E5E5), width: 0.5),
          ),
          child: TextFormField(
            controller: nameController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(10, 12, 10, 0),
              border: InputBorder.none,

              hintText: 'List Title',
              // hide default counter helper
              counterText: '',
              // pass the hint text parameter here
              hintStyle: TextStyle(color: Colors.grey),
            ),
            maxLength: controller.maxLength.value,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Cannot be empty';
              }
              return null;
            },
            onChanged: (value) => controller.updateWordCount(value),
          ),
        ),
      );
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Text(
          'Create Todo List',
          style: ToDoTheme.titleTextStyle,
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        color: ToDoTheme.dividerColor,
        endIndent: 10,
        indent: 10,
      );
}
