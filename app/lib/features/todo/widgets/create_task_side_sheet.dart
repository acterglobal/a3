import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/models/Team.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CreateTodoSideSheet extends StatefulWidget {
  final ToDoController controller;

  const CreateTodoSideSheet({Key? key, required this.controller})
      : super(key: key);

  @override
  State<CreateTodoSideSheet> createState() => _CreateTodoSideSheetState();
}

class _CreateTodoSideSheetState extends State<CreateTodoSideSheet> {
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
    return SideSheet(
      header: 'Create Task',
      body: SizedBox(
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
    return const Icon(Icons.done_outlined, size: 10);
  }
}

class _SelectTeamWidget extends StatefulWidget {
  final ToDoController controller;
  final TextEditingController nameController;

  const _SelectTeamWidget({
    required this.controller,
    required this.nameController,
  });

  @override
  State<_SelectTeamWidget> createState() => _SelectTeamWidgetState();
}

class _SelectTeamWidgetState extends State<_SelectTeamWidget> {
  final TextEditingController teamInputController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  RenderBox? overlay;
  Offset? tapXY;
  bool disableBtn = false;

  RelativeRect get relRectSize {
    return RelativeRect.fromSize(tapXY! & const Size(40, 40), overlay!.size);
  }

  void getPosition(TapDownDetails detail) {
    tapXY = detail.globalPosition;
  }

  @override
  Widget build(BuildContext context) {
    overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          GetBuilder<ToDoController>(
            id: 'teams',
            builder: (ToDoController controller) {
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.selectedTeam != null
                        ? controller.selectedTeam!.name!
                        : 'Select Team',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(Atlas.group_team_collective),
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
              style: Theme.of(ctx).textTheme.labelSmall,
            ),
          ),
        PopupMenuItem(
          //To prevent immediate pop up of context, use delay to show dialog.
          onTap: () => Future.delayed(
            const Duration(seconds: 0),
            () => _showTeamDialog(ctx),
          ),
          height: 24,
          child: Text(
            '+ Create Team',
            style: Theme.of(context).textTheme.labelSmall,
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
              title: Text(
                'Create new team',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              contentPadding: const EdgeInsets.all(13),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: (!disableBtn && teamInputController.text.isEmpty)
                      ? null
                      : () async {
                          await handleSave(ctx);
                        },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: teamInputController.text.isNotEmpty
                          ? Theme.of(context).colorScheme.tertiary2
                          : null,
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
                  decoration: InputDecoration(
                    filled: true,
                    hintText: 'Input here.',
                    contentPadding: const EdgeInsets.all(13),
                    border: const OutlineInputBorder(
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
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                  ),
                  onChanged: handleTeamInputChange,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> handleSave(BuildContext context) async {
    if (formGlobalKey.currentState!.validate()) {
      if (mounted) {
        setState(() => disableBtn = true);
        await widget.controller.createTeam(
          teamInputController.text,
          null,
          null,
        );
        setState(() => disableBtn = false);
        Navigator.pop(context);
      }
    }
  }

  void handleTeamInputChange(String value) {
    if (mounted) {
      setState(() {
        teamInputController.text = value;
        teamInputController.selection = TextSelection.fromPosition(
          TextPosition(offset: teamInputController.text.length),
        );
      });
    }
  }
}

class _CreateBtnWidget extends StatelessWidget {
  final ToDoController controller;
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const _CreateBtnWidget({
    required this.controller,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: controller.isLoading.isTrue
            ? const Center(
                child: CircularProgressIndicator(),
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
}

class _DescriptionInputWidget extends StatelessWidget {
  final TextEditingController descriptionController;

  const _DescriptionInputWidget({
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x18E5E5E5), width: 0.5),
      ),
      child: TextFormField(
        controller: descriptionController,
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          hintText: 'List Description',
          // pass the hint text parameter here
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        cursorColor: Theme.of(context).colorScheme.tertiary,
        maxLines: 5,
      ),
    );
  }
}

class _WordCountWidget extends StatelessWidget {
  final ToDoController controller;

  const _WordCountWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
        child: Text(
          'Word Count: ${controller.taskNameCount.value}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _NameInputWidget extends StatelessWidget {
  final TextEditingController nameController;
  final ToDoController controller;

  const _NameInputWidget({
    required this.nameController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x18E5E5E5), width: 0.5),
        ),
        child: TextFormField(
          controller: nameController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: 'List Title',
            // hide default counter helper
            counterText: '',
            // pass the hint text parameter here
          ),
          maxLength: controller.maxLength.value,
          style: Theme.of(context).textTheme.bodyMedium,
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
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        'Create Todo List',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      endIndent: 14,
      indent: 14,
    );
  }
}
