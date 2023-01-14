import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, FfiString, Group, Task, TaskList, TaskListDraft;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  final Client client;
  Group? defaultGroup;
  late final List<ToDoList>? todoList;
  int completedTasks = 0;
  int pendingTasks = 0;
  RxBool cardExpand = true.obs;
  RxBool expandBtn = false.obs;
  RxInt taskNameCount = 0.obs;
  RxInt selectedValueIndex = 0.obs;
  RxString selectedTeam = ''.obs;
  FocusNode addTaskNode = FocusNode();

  ToDoController({required this.client}) : super();

  Future<List<ToDoList>> getTodoList() async {
    List<ToDoList> todoLists = [];
    List<String> subscribers = [];

    /// only consider default group for testing purposes. Spaces design concept
    /// is needed for implementation.
    defaultGroup = (await client.groups()).toList()[0];
    if (defaultGroup != null) {
      List<TaskList> defaultGroupTaskLists =
          (await defaultGroup!.taskLists()).toList();

      for (TaskList todoList in defaultGroupTaskLists) {
        var users = todoList.subscribers();
        if (users.isNotEmpty) {
          for (var user in users.toList()) {
            subscribers.add(user.toString());
          }
        }
        var tasks = await getTodoTasks(todoList);
        calculateTasksRatio(tasks);
        ToDoList item = ToDoList(
          index: todoList.sortOrder(),
          name: todoList.name(),
          categories: asDartStringList(todoList.categories().toList()),
          tasks: tasks,
          completedTasks: completedTasks,
          pendingTasks: pendingTasks,
          subscribers: subscribers,
          color: todoList.color() as Color? ?? Colors.blue,
          description: todoList.descriptionText(),
          tags: asDartStringList(todoList.keywords().toList()),
          role: todoList.role(),
          timezone: todoList.timeZone(),
        );
        todoLists.add(item);
      }
      todoLists.sort((item1, item2) => item1.index.compareTo(item2.index));
      // reset count
      completedTasks = 0;
      pendingTasks = 0;
    }
    return todoLists;
  }

  Future<List<ToDoTask>> getTodoTasks(TaskList list) async {
    List<ToDoTask> todoTasks = [];
    List<String> assignees = [];
    List<String> subscribers = [];

    var tasksList = await list.tasks().then((tasks) => tasks.toList());
    for (Task task in tasksList) {
      if (task.assignees().isNotEmpty) {
        for (var user in task.subscribers().toList()) {
          assignees.add(user.toString());
        }
      }
      if (task.subscribers().isNotEmpty) {
        for (var user in task.subscribers().toList()) {
          subscribers.add(user.toString());
        }
      }
      ToDoTask item = ToDoTask(
        index: task.sortOrder(),
        name: task.title(),
        assignees: assignees,
        categories: asDartStringList(task.categories().toList()),
        isDone: task.isDone(),
        tags: asDartStringList(task.keywords().toList()),
        subscribers: subscribers,
        color: task.color() as Color? ?? Colors.blue,
        description: task.descriptionText() ?? '',
        priority: task.priority() ?? 0,
        progressPercent: task.progressPercent() ?? 0,
        start: DateTime.fromMillisecondsSinceEpoch(
          task.utcStart()!.timestamp(),
          isUtc: true,
        ),
        due: DateTime.fromMillisecondsSinceEpoch(
          task.utcDue()!.timestamp(),
          isUtc: true,
        ),
      );
      todoTasks.add(item);
    }
    todoTasks.sort(((item1, item2) => item1.index.compareTo(item2.index)));
    return todoTasks;
  }

  Future<String> createToDoList(String name, String? description) async {
    TaskListDraft taskListDraft = defaultGroup!.taskListDraft();
    taskListDraft.name(name);
    taskListDraft.descriptionText(description!);
    var eventId = await taskListDraft.send();
    return eventId.toString();
  }

  void updateButtonIndex(int index) {
    selectedValueIndex.value = index;
  }

  //ToDo list card expand.
  void toggleCardExpand() {
    cardExpand.value = !cardExpand.value;
  }

  // Completed tasks expand.
  void toggleExpandBtn() {
    expandBtn.value = !expandBtn.value;
  }

  // setter for selected team.
  void setSelectedTeam(String val) {
    selectedTeam.value = val;
  }

  // max length counter for task name.
  void updateWordCount(int val) {
    if (val == 0) {
      taskNameCount.value = 30;
    } else {
      taskNameCount.value = 30 - val;
    }
  }

  //calculate completed and pending tasks
  void calculateTasksRatio(List<ToDoTask> tasks) {
    for (ToDoTask task in tasks) {
      if (task.isDone) {
        completedTasks += 1;
      } else {
        pendingTasks += 1;
      }
    }
  }

  //helper function to convert list ffiString object to DartString.
  List<String> asDartStringList(List<FfiString> list) {
    final List<String> stringList =
        list.map((ffiString) => ffiString.toDartString()).toList();
    return stringList;
  }

  // void handleCheckClick(int position) {
  //   var subscribeModel = listSubscribers[position];
  //   if (subscribeModel.isSelected) {
  //     subscribeModel.isSelected = false;
  //   } else {
  //     subscribeModel.isSelected = true;
  //   }
  //   update(['subscribeUser']);
  // }

  // bool toggleCheck(int idx, ToDoTaskItem item) {
  //   if (item.isCompleted == true) {
  //     ToDoTaskItem newItem = ToDoTaskItem(
  //       title: item.title,
  //       isCompleted: false,
  //       hasMessage: item.hasMessage,
  //       dateTime: item.dateTime,
  //       subtitle: item.subtitle,
  //       notes: item.notes,
  //       lastUpdated: item.lastUpdated,
  //       toggleCompletion: (w) => toggleCheck(idx, w),
  //     );
  //     tasks[idx].remove(item);
  //     tasks[idx].add(newItem);
  //     return false;
  //   } else {
  //     ToDoTaskItem newItem = ToDoTaskItem(
  //       title: item.title,
  //       isCompleted: true,
  //       hasMessage: item.hasMessage,
  //       dateTime: item.dateTime,
  //       subtitle: item.subtitle,
  //       notes: item.notes,
  //       lastUpdated: item.lastUpdated,
  //       toggleCompletion: (w) => toggleCheck(idx, w),
  //     );
  //     tasks[idx].remove(item);
  //     tasks[idx].add(newItem);
  //     return true;
  //   }
  // }

  // void updateNotes(ToDoTaskItem item, TextEditingController textController) {
  //   var idx = 0;
  //   var dateTime = DateTime.now();
  //   ToDoTaskItem newItem = ToDoTaskItem(
  //     title: item.title,
  //     isCompleted: item.isCompleted,
  //     hasMessage: item.hasMessage,
  //     dateTime: item.dateTime,
  //     subtitle: item.subtitle,
  //     notes: textController.text,
  //     lastUpdated: dateTime,
  //     toggleCompletion: (w) => toggleCheck(idx, w),
  //   );
  //   update(['notes']);
  //   tasks[idx].remove(item);
  //   tasks[idx].add(newItem);
  // }

  // void updateSubtitle(ToDoTaskItem item, TextEditingController textController) {
  //   var idx = 0;
  //   var dateTime = DateTime.now();
  //   ToDoTaskItem newItem = ToDoTaskItem(
  //     title: item.title,
  //     isCompleted: item.isCompleted,
  //     hasMessage: item.hasMessage,
  //     dateTime: item.dateTime,
  //     subtitle: textController.text,
  //     notes: item.notes,
  //     lastUpdated: dateTime,
  //     toggleCompletion: (w) => toggleCheck(idx, w),
  //   );
  //   update(['subtitle']);
  //   tasks[idx].remove(item);
  //   tasks[idx].add(newItem);
  // }
}
