import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/models/SubscriberModel.dart';
import 'package:effektio/widgets/ToDoListView.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToDoController extends GetxController {
  static ToDoController get instance =>
      Get.put<ToDoController>(ToDoController());
  late final List<ToDoListView>? todoList;
  late final List<ToDoTaskItem>? tasksList;
  List<RxList<ToDoTaskItem>> tasks = <RxList<ToDoTaskItem>>[].obs;
  late int listCount;
  late int taskCount;
  late int likeCount;
  late int messageCount;
  RxBool initialExpand = true.obs;
  RxBool expandBtn = false.obs;
  int selectedValueIndex = 0;
  Random random = Random();
  FocusNode addTaskNode = FocusNode();

  // initialize todolist and tasks.
  void init() {
    taskCount = random.nextInt(8) + 1;
    listCount = random.nextInt(10) + 3;
    likeCount = random.nextInt(100);
    messageCount = random.nextInt(100);
    todoList = [
      const ToDoListView(
        title: 'Groceries',
        subtitle: 'General shopping list',
        idx: 0,
      ),
      const ToDoListView(
        title: 'Uncle Jack\'s 65th Birthday party',
        subtitle: 'Things to do for organizing the birthday party no the 17th.',
        idx: 1,
      ),
      const ToDoListView(
        title: '25th Anniversary of Club Sporting',
        subtitle:
            'Party on the 3rd, 4pm @ Club House. All unassigned tasks are up for grabs - take it and do it. Sync-Call every tuesday and thursday at 6pm.',
        idx: 2,
      ),
      const ToDoListView(
        title: 'Errands',
        subtitle: 'General family errands',
        idx: 3,
      ),
      const ToDoListView(
        title: 'Kids & School',
        subtitle:
            'Everything around the kids and school, that needs to be done, listed here',
        idx: 4,
      ),
    ];

    // groceries
    tasks.add(
      [
        ToDoTaskItem(
          title: 'Milk',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(0, w),
        ),
        ToDoTaskItem(
          title: 'Coffee',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(0, w),
        ),
        ToDoTaskItem(
          title: 'Orange Juice',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(0, w),
        ),
        ToDoTaskItem(
          title: 'Eggs',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(0, w),
        ),
      ].obs,
    );
    // uncle jacks
    tasks.add(
      [
        ToDoTaskItem(
          title: 'Buy Birthday cake',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Birthday decorations',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Clarify whether Erna is gonna be there',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Organize bus transport',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'for approx 40ppl',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Collect RSVPs',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Send invitations',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
        ToDoTaskItem(
          title: 'Create guest list',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(1, w),
        ),
      ].obs,
    );
    // sport club
    tasks.add(
      [
        ToDoTaskItem(
          title: 'Make Brownies',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(2, w),
        ),
        ToDoTaskItem(
          title: 'Rent tent',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'for about 160ppl in case of rain',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(2, w),
        ),
        ToDoTaskItem(
          title: 'Send invitations',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(2, w),
        ),
      ].obs,
    );

    // errands
    tasks.add(
      [
        ToDoTaskItem(
          title: 'Bring the car to the shop',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'for general inspection',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(3, w),
        ),
        ToDoTaskItem(
          title: 'Answer the city counsel request',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'about the new construction project',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(3, w),
        ),
        ToDoTaskItem(
          title: 'Make an vet appointment for the doc',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'yearly checkup',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(3, w),
        ),
        ToDoTaskItem(
          title: 'Replace the trash can',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'for general inspection',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(3, w),
        ),
        ToDoTaskItem(
          title: 'Fix the door handle',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'for general inspection',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(3, w),
        ),
      ].obs,
    );

    // kids & school
    tasks.add(
      [
        ToDoTaskItem(
          title: 'Answer the school secretary',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: 'about the passport',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(4, w),
        ),
        ToDoTaskItem(
          title: 'Put up nanny job ad',
          isCompleted: false,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(4, w),
        ),
        ToDoTaskItem(
          title: 'Get Kim new soccer excercise cloths',
          isCompleted: true,
          hasMessage: random.nextBool(),
          dateTime: taskDue[random.nextInt(taskDue.length)],
          subtitle: '',
          notes: null,
          lastUpdated: DateTime.now(),
          toggleCompletion: (w) => toggleCheck(4, w),
        ),
      ].obs,
    );
  }

  // Mock data for subscribed users
  List<SubscriberModel> listSubscribers = <SubscriberModel>[
    SubscriberModel('', 'Okon Invincible', false),
    SubscriberModel('', 'Floym Dore', false),
    SubscriberModel('', 'Raveena Tondon', false),
    SubscriberModel('', 'Karishma Kapoor', false),
    SubscriberModel('', 'Hema Malini', false),
    SubscriberModel('', 'John Doe', false),
  ];

  void handleCheckClick(int position) {
    var subscribeModel = listSubscribers[position];
    if (subscribeModel.isSelected) {
      subscribeModel.isSelected = false;
    } else {
      subscribeModel.isSelected = true;
    }
    update(['subscribeUser']);
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

  bool toggleCheck(int idx, ToDoTaskItem item) {
    if (item.isCompleted == true) {
      ToDoTaskItem newItem = ToDoTaskItem(
        title: item.title,
        isCompleted: false,
        hasMessage: item.hasMessage,
        dateTime: item.dateTime,
        subtitle: item.subtitle,
        notes: item.notes,
        lastUpdated: item.lastUpdated,
        toggleCompletion: (w) => toggleCheck(idx, w),
      );
      tasks[idx].remove(item);
      tasks[idx].add(newItem);
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
        toggleCompletion: (w) => toggleCheck(idx, w),
      );
      tasks[idx].remove(item);
      tasks[idx].add(newItem);
      return true;
    }
  }

  void updateNotes(ToDoTaskItem item, TextEditingController textController) {
    var idx = 0;
    var dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: item.subtitle,
      notes: textController.text,
      lastUpdated: dateTime,
      toggleCompletion: (w) => toggleCheck(idx, w),
    );
    update(['notes']);
    tasks[idx].remove(item);
    tasks[idx].add(newItem);
  }

  void updateSubtitle(ToDoTaskItem item, TextEditingController textController) {
    var idx = 0;
    var dateTime = DateTime.now();
    ToDoTaskItem newItem = ToDoTaskItem(
      title: item.title,
      isCompleted: item.isCompleted,
      hasMessage: item.hasMessage,
      dateTime: item.dateTime,
      subtitle: textController.text,
      notes: item.notes,
      lastUpdated: dateTime,
      toggleCompletion: (w) => toggleCheck(idx, w),
    );
    update(['subtitle']);
    tasks[idx].remove(item);
    tasks[idx].add(newItem);
  }
}
