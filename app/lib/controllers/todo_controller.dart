// ignore_for_file: always_declare_return_types

import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/widget/ToDoListView.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  static ToDoController get instance =>
      Get.put<ToDoController>(ToDoController());
  late final List<ToDoListView>? todoList;
  late final List<ToDoTaskItem>? tasksList;
  RxList<ToDoTaskItem> completedTasks = <ToDoTaskItem>[].obs;
  RxList<ToDoTaskItem> pendingTasks = <ToDoTaskItem>[].obs;
  late int listCount;
  late int taskCount;
  late int likeCount;
  late int messageCount;
  RxBool initialExpand = false.obs;
  RxBool expandBtn = false.obs;
  int selectedValueIndex = 0;
  Random random = Random();

  // initialize todolist and tasks.
  init() {
    taskCount = random.nextInt(8) + 1;
    listCount = random.nextInt(10) + 3;
    likeCount = random.nextInt(100);
    messageCount = random.nextInt(100);
    tasksList = List.generate(
      taskCount,
      (index) => ToDoTaskItem(
        title: titleTasks[random.nextInt(titleTasks.length)],
        isCompleted: random.nextBool(),
        hasMessage: random.nextBool(),
        dateTime: taskDue[random.nextInt(taskDue.length)],
      ),
    );
    todoList = List.generate(
      listCount,
      (index) => ToDoListView(
        title: titleTasks[random.nextInt(titleTasks.length)],
        subtitle: loremPara2,
      ),
    );
    for (var t in tasksList!) {
      if (t.isCompleted) {
        completedTasks.add(t);
      } else {
        pendingTasks.add(t);
      }
    }
  }

  void updateIndex(int index) {
    selectedValueIndex = index;
    update(['radiobtn']);
  }

  void toggleExpand() {
    initialExpand.value = !initialExpand.value;
  }

  void toggleExpandBtn() {
    expandBtn.value = !expandBtn.value;
  }

  void toggleCheck(ToDoTaskItem item) {
    if (item.isCompleted) {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: false,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
      );
      pendingTasks.remove(item);
      completedTasks.add(newItem);
    } else {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: true,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
      );
      completedTasks.remove(item);
      pendingTasks.add(newItem);
    }
  }
}
