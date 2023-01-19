import 'package:effektio/models/Team.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        CreateGroupSettings,
        FfiString,
        Group,
        RoomProfile,
        Task,
        TaskDraft,
        TaskList,
        TaskListDraft,
        TaskUpdateBuilder;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  final Client client;
  late final List<ToDoList>? todoList;
  bool cardExpand = false;
  bool expandBtn = false;
  RxInt taskNameCount = 0.obs;
  RxInt selectedValueIndex = 0.obs;
  Team? selectedTeam;
  FocusNode addTaskNode = FocusNode();

  ToDoController({required this.client}) : super();

  Future<void> createTeam(String name) async {
    final sdk = await EffektioSdk.instance;
    CreateGroupSettings settings = sdk.newGroupSettings(name);
    settings.alias(UniqueKey().toString());
    settings.visibility('Public');
    settings.addInvitee('@sisko:matrix.org');
    await client.createEffektioGroup(settings);
  }

  Future<List<Team>> getTeams() async {
    List<Team> teams = [];
    List<Group> listTeams =
        await client.groups().then((groups) => groups.toList());
    if (listTeams.isNotEmpty) {
      for (var team in listTeams) {
        RoomProfile teamProfile = await team.getProfile();
        // Team avatars are yet to be implemented.
        Team item = Team(
          id: team.getRoomId(),
          name: teamProfile.getDisplayName(),
        );
        teams.add(item);
      }
    }
    return teams;
  }

  Future<List<ToDoList>> getTodoList() async {
    List<ToDoList> todoLists = [];
    List<String> subscribers = [];
    List<TaskList> taskLists =
        await client.taskLists().then((data) => data.toList());
    for (TaskList todoList in taskLists) {
      var users = todoList.subscribers();
      if (users.isNotEmpty) {
        for (var user in users.toList()) {
          subscribers.add(user.toString());
        }
      }

      List<ToDoTask> tasks = await getTodoTasks(todoList);
      ToDoList item = ToDoList(
        index: todoList.sortOrder(),
        name: todoList.name(),
        categories: asDartStringList(todoList.categories().toList()) ?? [],
        taskDraft: todoList.taskBuilder(),
        taskUpdateDraft: todoList.updateBuilder(),
        tasks: tasks,
        subscribers: subscribers,
        color: todoList.color() as Color?,
        description: todoList.descriptionText() ?? '',
        tags: asDartStringList(todoList.keywords().toList()) ?? [],
        role: todoList.role() ?? '',
        timezone: todoList.timeZone() ?? '',
      );
      todoLists.add(item);
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
        taskUpdateDraft: task.updateBuilder(),
        assignees: assignees,
        categories: asDartStringList(task.categories().toList()) ?? [],
        isDone: task.isDone(),
        tags: asDartStringList(task.keywords().toList()) ?? [],
        subscribers: subscribers,
        color: task.color() as Color?,
        description: task.descriptionText() ?? '',
        priority: task.priority() ?? 0,
        progressPercent: task.progressPercent() ?? 0,
        due: DateTime.parse(task.utcDue()!.toRfc3339()),
      );
      todoTasks.add(item);
    }
    return todoTasks;
  }

  Future<String> createToDoList(
    String teamId,
    String name,
    String? description,
  ) async {
    Group group = await client.getGroup(teamId);
    TaskListDraft listDraft = group.taskListDraft();

    listDraft.name(name);
    listDraft.descriptionText(description!);
    var eventId = await listDraft.send();
    await client.waitForTaskList(eventId.toString(), null);
    update(['refresh-list']);
    return eventId.toString();
  }

  Future<String> createToDoTask({
    required String name,
    required TaskDraft taskDraft,
    required DateTime? dueDate,
  }) async {
    taskDraft.title(name);
    taskDraft.utcDueFromRfc3339(dueDate!.toIso8601String());
    String eventId = await taskDraft.send().then((res) => res.toString());
    await client.waitForTask(eventId, null);
    update(['refresh-list']);
    return eventId;
  }

  Future<String> markToDoTask(TaskUpdateBuilder taskDraft, bool check) async {
    if (check) {
      taskDraft.markDone();
    } else {
      taskDraft.markUndone();
    }
    String eventId =
        await taskDraft.send().then((eventId) => eventId.toString());
    return eventId;
  }

  void updateButtonIndex(int index) {
    selectedValueIndex.value = index;
  }

  //ToDo list card expand.
  void toggleCardExpand(int index) {
    cardExpand = !cardExpand;
    update(['list-item-$index']);
  }

  // Completed tasks expand.
  void toggleExpandBtn(index) {
    expandBtn = !expandBtn;
    update(['list-item-$index']);
  }

  // setter for selected team.
  void setSelectedTeam(Team? val) {
    selectedTeam = val;
    update(['teams']);
  }

  // max length counter for task name.
  void updateWordCount(int val) {
    if (val == 0) {
      taskNameCount.value = 30;
      selectedTeam = null;
      update(['teams']);
    } else {
      taskNameCount.value = 30 - val;
      update(['teams']);
    }
  }

  // get completed tasks.
  int getCompletedTasks(ToDoList list) {
    int count = 0;
    for (var item in list.tasks) {
      if (item.isDone) {
        count += 1;
      }
    }
    return count;
  }

  //helper function to convert list ffiString object to DartString.
  List<String>? asDartStringList(List<FfiString> list) {
    if (list.isNotEmpty) {
      final List<String> stringList =
          list.map((ffiString) => ffiString.toDartString()).toList();
      return stringList;
    }
    return null;
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
