import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/todo_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoListView extends StatelessWidget {
  const ToDoListView({Key? key, required this.controller}) : super(key: key);
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => controller.todos.isEmpty
          ? const Center(
              heightFactor: 10,
              child: Text(
                'You do not have any todos!',
                style: ToDoTheme.titleTextStyle,
              ),
            )
          : ListView.builder(
              itemCount: controller.todos.length,
              shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                return GetBuilder<ToDoController>(
                  id: 'list-item-$index',
                  builder: (_) {
                    return TodoCard(
                      controller: controller,
                      index: index,
                      isExpanded: controller.cardExpand,
                      expandBtn: controller.expandBtn,
                    );
                  },
                );
              },
            ),
    );
  }
}
