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
        TaskList,
        TaskListDraft;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  final Client client;
  final RxList<ToDoList> todos = <ToDoList>[].obs;
  bool cardExpand = false;
  bool expandBtn = false;
  RxInt taskNameCount = 0.obs;
  RxInt selectedValueIndex = 0.obs;
  Team? selectedTeam;
  FocusNode addTaskNode = FocusNode();

  ToDoController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();
    getTodoList();
  }

  /// creates team (group).
  Future<void> createTeam(String name) async {
    final sdk = await EffektioSdk.instance;
    CreateGroupSettings settings = sdk.newGroupSettings(name);
    settings.alias(UniqueKey().toString());
    settings.visibility('Public');
    settings.addInvitee('@sisko:matrix.org');
    await client.createEffektioGroup(settings);
  }

  /// fetches teams (groups) for client.
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

  /// fetches todos for client.
  void getTodoList() async {
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
      todos.add(item);
    }
  }

  /// fetches todo tasks.
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

  /// creates todo for team (group).
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
    TaskList list = await client.waitForTaskList(eventId.toString(), null);
    List<ToDoTask> tasksList = await getTodoTasks(list);
    final ToDoList newItem = ToDoList(
      name: list.name(),
      description: list.descriptionText() ?? '',
      tasks: tasksList,
      taskDraft: list.taskBuilder(),
      taskUpdateDraft: list.updateBuilder(),
    );
    todos.add(newItem);
    todos.refresh();
    return eventId.toString();
  }

  /// creates todo task.
  Future<String> createToDoTask({
    required String name,
    required DateTime? dueDate,
    required ToDoList list,
  }) async {
    list.taskDraft.title(name);
    list.taskDraft.utcDueFromRfc3339(dueDate!.toIso8601String());
    String eventId = await list.taskDraft.send().then((res) => res.toString());
    // wait for task to come down to wire.
    Task task = await client.waitForTask(eventId, null);

    ToDoTask newItem = ToDoTask(
      name: task.title(),
      progressPercent: task.progressPercent() ?? 0,
      taskUpdateDraft: task.updateBuilder(),
      due: DateTime.parse(
        task.utcDue()!.toRfc3339(),
      ),
    );
    // append new task to existing list.
    List<ToDoTask> tasksList = [...list.tasks, newItem];
    int idx = todos.indexOf(list);

    // update todos.
    todos[idx] = list.copyWith(
      name: list.name,
      taskDraft: list.taskDraft,
      taskUpdateDraft: list.taskUpdateDraft,
      tasks: tasksList,
    );
    return eventId;
  }

  /// updates todo task progress.
  Future<String> markToDoTask(ToDoTask task, ToDoList list) async {
    int updateVal = 0;
    if (task.progressPercent < 100) {
      task.taskUpdateDraft.markDone();
      updateVal = 100;
    } else {
      task.taskUpdateDraft.markUndone();
    }
    // send task update.
    String eventId =
        await task.taskUpdateDraft.send().then((eventId) => eventId.toString());
    ToDoTask updateItem = ToDoTask(
      name: task.name,
      progressPercent: updateVal,
      taskUpdateDraft: task.taskUpdateDraft,
      due: task.due,
    );
    // update todos.
    int idx = list.tasks.indexOf(task);
    int listIdx = todos.indexOf(list);
    ToDoList newList = list;
    newList.tasks[idx] = task.copyWith(
      name: updateItem.name,
      taskUpdateDraft: updateItem.taskUpdateDraft,
      progressPercent: updateItem.progressPercent,
      due: updateItem.due,
    );
    todos[listIdx] = newList;
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
      if (item.progressPercent >= 100) {
        count += 1;
      }
    }
    return count;
  }

  ///helper function to convert list ffiString object to DartString.
  List<String>? asDartStringList(List<FfiString> list) {
    if (list.isNotEmpty) {
      final List<String> stringList =
          list.map((ffiString) => ffiString.toDartString()).toList();
      return stringList;
    }
    return null;
  }
}
