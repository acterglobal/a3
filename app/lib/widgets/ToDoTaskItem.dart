import 'dart:math';

import 'package:avatar_stack/positions.dart';
import 'package:beamer/beamer.dart';
import 'package:effektio/models/TodoTaskEditorModel.dart';
import 'package:effektio/widgets/CompletedTaskCard.dart';
import 'package:effektio/widgets/IncompleteTaskCard.dart';
import 'package:flutter/material.dart';

class ToDoTaskItem extends StatefulWidget {
  final String title;
  final bool hasMessage;
  final bool isCompleted;
  final Function toggleCompletion;
  final String dateTime;
  final String subtitle;
  final String? notes;
  final DateTime? lastUpdated;

  const ToDoTaskItem({
    Key? key,
    required this.title,
    this.isCompleted = false,
    this.hasMessage = false,
    required this.toggleCompletion,
    required this.dateTime,
    required this.subtitle,
    required this.notes,
    required this.lastUpdated,
  }) : super(key: key);

  @override
  State<ToDoTaskItem> createState() => _ToDoTaskItemState();
}

class _ToDoTaskItemState extends State<ToDoTaskItem> {
  bool isAllDay = false;
  late List<ImageProvider<Object>> avatars;
  final int countPeople = Random().nextInt(10);
  final int messageCount = Random().nextInt(100);
  int id = Random().nextInt(70);
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.right,
  );

  @override
  void initState() {
    super.initState();

    avatars = getMockAvatars(countPeople);
    if (widget.dateTime.contains('All Day')) {
      isAllDay = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Beamer.of(context).beamToNamed('/todoTaskEditor', data: TodoTaskEditorModel(item: widget, avatars: avatars));
      },
      child: widget.isCompleted
          ? CompletedTaskCard(title: widget.title, isCompleted: widget.isCompleted, dateTime: widget.dateTime, toggleCompletion: widget.toggleCompletion, hasMessage: widget.hasMessage, avatars: avatars)
          : IncompleteTaskCard(title: widget.title, isCompleted: widget.isCompleted, dateTime: widget.dateTime, toggleCompletion: widget.toggleCompletion, hasMessage: widget.hasMessage, avatars: avatars),
    );
  }

  List<ImageProvider<Object>> getMockAvatars(int count) {
    return List.generate(count, (index) {
      int id = Random().nextInt(70);
      return NetworkImage('https://i.pravatar.cc/100?img = ${id.toString()}');
    });
  }

}
