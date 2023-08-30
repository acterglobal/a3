import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/todo/controllers/todo_controller.dart';
import 'package:acter/features/todo/widgets/create_task_side_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class AddTaskActionSideSheet extends ConsumerWidget {
  const AddTaskActionSideSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;

    return CreateTodoSideSheet(
      controller: Get.put(ToDoController(client: client)),
    );
  }
}
