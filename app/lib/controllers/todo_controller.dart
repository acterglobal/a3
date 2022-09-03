// ignore_for_file: always_declare_return_types

import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/widget/ToDoListView.dart';
import 'package:effektio/common/widget/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';
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
        subtitle: lorem(paragraphs: 1, words: 20),
        notes: null,
        lastUpdated: DateTime.now(),
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
      if (t.isCompleted == true) {
        completedTasks.add(t);
      } else if (t.isCompleted == false) {
        pendingTasks.add(t);
      }
    }
    debugPrint('Completed: $completedTasks');
    debugPrint('Pending: $pendingTasks');
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
    if (item.isCompleted == true) {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: false,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
        subtitle: item.subtitle,
        notes: item.notes,
      );
      pendingTasks.add(newItem);
      completedTasks.remove(item);
    } else if (item.isCompleted == false) {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: true,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
        subtitle: item.subtitle,
        notes: item.notes,
      );
      completedTasks.add(newItem);
      pendingTasks.remove(item);
    }
  }

  void updateNotes(ToDoTaskItem item, TextEditingController textController) {
    var _dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: item.subtitle,
      notes: textController.text,
      lastUpdated: _dateTime,
    );
    update(['notes']);
    if (newItem.isCompleted) {
      completedTasks.add(newItem);
      completedTasks.remove(item);
    } else {
      pendingTasks.add(newItem);
      pendingTasks.remove(item);
    }
  }

  void updateSubtitle(ToDoTaskItem item, TextEditingController textController) {
    var _dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: textController.text,
      notes: item.notes,
      lastUpdated: _dateTime,
    );
    update(['subtitle']);
    if (newItem.isCompleted) {
      completedTasks.add(newItem);
      completedTasks.remove(item);
    } else {
      pendingTasks.add(newItem);
      pendingTasks.remove(item);
    }
  }
}
