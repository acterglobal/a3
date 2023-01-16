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
  late final List<ToDoList>? todoList;
  RxList<ToDoTask> draftToDoTasks = <ToDoTask>[].obs;
  int completedTasks = 0;
  int pendingTasks = 0;
  RxBool cardExpand = true.obs;
  RxBool expandBtn = false.obs;
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
      calculateTasksRatio(tasks);
      ToDoList item = ToDoList(
        index: todoList.sortOrder(),
        name: todoList.name(),
        categories: asDartStringList(todoList.categories().toList()) ?? [],
        tasks: tasks,
        completedTasks: completedTasks,
        pendingTasks: pendingTasks,
        subscribers: subscribers,
        color: todoList.color() as Color?,
        description: todoList.descriptionText() ?? '',
        tags: asDartStringList(todoList.keywords().toList()) ?? [],
        role: todoList.role() ?? '',
        timezone: todoList.timeZone() ?? '',
      );
      todoLists.add(item);
    }
    // reset count
    completedTasks = 0;
    pendingTasks = 0;

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
        categories: asDartStringList(task.categories().toList()) ?? [],
        isDone: task.isDone(),
        tags: asDartStringList(task.keywords().toList()) ?? [],
        subscribers: subscribers,
        color: task.color() as Color?,
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
    return eventId.toString();
  }

  void createToDoTaskDraft(String name, String? description, bool isDone) {
    ToDoTask item = ToDoTask(
      index: 0,
      name: name,
      description: description ?? '',
      isDone: isDone,
    );
    draftToDoTasks.add(item);
  }

  void updateToDoTaskDraft(
    String name,
    String? description,
    bool isDone,
    int idx,
  ) {
    ToDoTask item = ToDoTask(
      index: 0,
      name: name,
      description: description ?? '',
      isDone: isDone,
    );
    draftToDoTasks.remove(draftToDoTasks[idx]);
    draftToDoTasks.insert(idx, item);
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
