import 'package:effektio/models/ToDoList.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        CreateGroupSettings,
        FfiListFfiString,
        FfiString,
        Task,
        TaskList;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  final Client client;
  late final List<ToDoList>? todoList;
  int completedTasks = 0;
  int pendingTasks = 0;
  RxBool cardExpand = true.obs;
  RxBool expandBtn = false.obs;
  RxInt selectedValueIndex = 0.obs;
  FocusNode addTaskNode = FocusNode();

  ToDoController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();
    createDefaultGroup();
  }

  Future<void> createDefaultGroup() async {
    var groups = (await client.groups()).toList();
    final sdk = await EffektioSdk.instance;
    CreateGroupSettings settings = sdk.newGroupSettings('Bob');
    settings.alias('bob');
    settings.visibility('Public');
    settings.addInvitee('@sisko:matrix.org');

    if (groups.isEmpty && !client.isGuest()) {
      await client.createEffektioGroup(settings);
    }
  }

  Future<List<ToDoList>> getTodoList() async {
    List<ToDoList> todoLists = [];
    List<String> subscribers = [];
    List<TaskList> groupTaskLists =
        await client.taskLists().then((todos) => todos.toList());
    for (TaskList todoList in groupTaskLists) {
      if (todoList.subscribers().isNotEmpty) {
        for (var user in todoList.subscribers().toList()) {
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
        color: todoList.color() as Color?,
        description: todoList.descriptionText() ?? '',
        tags: asDartStringList(todoList.keywords().toList()),
        role: todoList.role() ?? '',
        timezone: todoList.timeZone(),
      );
      todoLists.add(item);
    }
    todoLists.sort(((item1, item2) => item1.index.compareTo(item2.index)));
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
        categories: asDartStringList(task.categories().toList()),
        isDone: task.isDone(),
        tags: asDartStringList(task.keywords().toList()),
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
    todoTasks.sort(((item1, item2) => item1.index.compareTo(item2.index)));
    return todoTasks;
  }

  void updateButtonIndex(int index) {
    selectedValueIndex.value = index;
  }

  ///ToDo list card expand.
  void toggleCardExpand() {
    cardExpand.value = !cardExpand.value;
  }

  /// Completed tasks expand.
  void toggleExpandBtn() {
    expandBtn.value = !expandBtn.value;
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
  // // initialize todolist and tasks.
  // void init() {
  //   taskCount = random.nextInt(8) + 1;
  //   listCount = random.nextInt(10) + 3;
  //   likeCount = random.nextInt(100);
  //   messageCount = random.nextInt(100);

  //   // groceries
  //   tasks.add(
  //     [
  //       ToDoTaskItem(
  //         title: 'Milk',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(0, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Coffee',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(0, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Orange Juice',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(0, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Eggs',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(0, w),
  //       ),
  //     ].obs,
  //   );
  //   // uncle jacks
  //   tasks.add(
  //     [
  //       ToDoTaskItem(
  //         title: 'Buy Birthday cake',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Birthday decorations',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Clarify whether Erna is gonna be there',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Organize bus transport',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'for approx 40ppl',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Collect RSVPs',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Send invitations',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Create guest list',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(1, w),
  //       ),
  //     ].obs,
  //   );
  //   // sport club
  //   tasks.add(
  //     [
  //       ToDoTaskItem(
  //         title: 'Make Brownies',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(2, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Rent tent',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'for about 160ppl in case of rain',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(2, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Send invitations',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(2, w),
  //       ),
  //     ].obs,
  //   );

  //   // errands
  //   tasks.add(
  //     [
  //       ToDoTaskItem(
  //         title: 'Bring the car to the shop',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'for general inspection',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(3, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Answer the city counsel request',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'about the new construction project',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(3, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Make an vet appointment for the doc',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'yearly checkup',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(3, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Replace the trash can',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'for general inspection',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(3, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Fix the door handle',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'for general inspection',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(3, w),
  //       ),
  //     ].obs,
  //   );

  //   // kids & school
  //   tasks.add(
  //     [
  //       ToDoTaskItem(
  //         title: 'Answer the school secretary',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: 'about the passport',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(4, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Put up nanny job ad',
  //         isCompleted: false,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(4, w),
  //       ),
  //       ToDoTaskItem(
  //         title: 'Get Kim new soccer excercise cloths',
  //         isCompleted: true,
  //         hasMessage: random.nextBool(),
  //         dateTime: taskDue[random.nextInt(taskDue.length)],
  //         subtitle: '',
  //         notes: null,
  //         lastUpdated: DateTime.now(),
  //         toggleCompletion: (w) => toggleCheck(4, w),
  //       ),
  //     ].obs,
  //   );
  // }

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
