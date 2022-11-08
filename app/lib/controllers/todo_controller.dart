import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/widgets/ToDoListView.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
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
  RxBool initialExpand = true.obs;
  RxBool expandBtn = false.obs;
  int selectedValueIndex = 0;
  Random random = Random();

  // initialize todolist and tasks.
  void init() {
    taskCount = random.nextInt(8) + 1;
    listCount = random.nextInt(10) + 3;
    likeCount = random.nextInt(100);
    messageCount = random.nextInt(100);
    tasksList = List.generate(taskCount, (index) {
      return ToDoTaskItem(
        title: titleTasks[random.nextInt(titleTasks.length)],
        isCompleted: random.nextBool(),
        hasMessage: random.nextBool(),
        dateTime: taskDue[random.nextInt(taskDue.length)],
        subtitle: lorem(paragraphs: 1, words: 20),
        notes: null,
        lastUpdated: DateTime.now(),
      );
    });
    todoList = [
      const ToDoListView(
        title: 'Groceries',
        subtitle: 'General shopping list',
      ),
      const ToDoListView(
        title: 'Uncle Jack\'s 65th Birthday party',
        subtitle: 'Things to do for organizing the birthday party no the 17th.',
      ),
      const ToDoListView(
        title: '25th Anniversary of Club Sporting',
        subtitle:
            'Party on the 3rd, 4pm @ Club House. All unassigned tasks are up for grabs - take it and do it. Sync-Call every tuesday and thursday at 6pm.',
      ),
      const ToDoListView(
        title: 'Errands',
        subtitle: 'General family errands',
      ),
      const ToDoListView(
        title: 'Kids & School',
        subtitle:
            'Everything around the kids and school, that needs to be done, listed here',
      ),
    ];
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

  bool toggleCheck(ToDoTaskItem item) {
    if (item.isCompleted == true) {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: false,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
        subtitle: item.subtitle,
        notes: item.notes,
        lastUpdated: item.lastUpdated,
      );
      pendingTasks.add(newItem);
      completedTasks.remove(item);
      return false;
    } else {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: true,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
        subtitle: item.subtitle,
        notes: item.notes,
        lastUpdated: item.lastUpdated,
      );
      completedTasks.add(newItem);
      pendingTasks.remove(item);
      return true;
    }
  }

  void updateNotes(ToDoTaskItem item, TextEditingController textController) {
    var dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: item.subtitle,
      notes: textController.text,
      lastUpdated: dateTime,
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
    var dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: textController.text,
      notes: item.notes,
      lastUpdated: dateTime,
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
