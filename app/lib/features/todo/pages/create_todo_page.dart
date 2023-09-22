import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
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
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Atlas.arrow_left_circle,
            color: Colors.white,
          ),
        ),
      ),
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
    return const Icon(
      Icons.done_outlined,
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
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    widget.controller.selectedTeam != null
                        ? widget.controller.selectedTeam!.name!
                        : 'Select Team',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Icon(
              Atlas.group_team_collective,
            ),
          ),
        ],
      ),
    );
  }

  void _showPopupMenu(BuildContext ctx) async {}

  Future<void> handleSave(BuildContext context) async {}

  void handleTeamInputChange(String value) {}
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
                  child: CircularProgressIndicator(),
                )
              : DefaultButton(
                  onPressed: (controller.taskNameCount < 30 &&
                          nameController.text.trim().isNotEmpty)
                      ? () async {
                          controller.isLoading.value = true;
                          final eventId = await controller.createToDoList(
                            controller.selectedTeam!.id,
                            nameController.text.trim(),
                            descriptionController.text.trim(),
                          );
                          debugPrint('ToDo CREATED: $eventId');
                          controller.isLoading.value = false;
                          // Navigator.pop(context);
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
            style: Theme.of(context).textTheme.labelMedium,
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

class _TitleWidget extends StatelessWidget {
  const _TitleWidget();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Text(
          'Create Todo List',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        endIndent: 14,
        indent: 14,
      );
}
