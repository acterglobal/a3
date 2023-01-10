import 'dart:math';

import 'package:avatar_stack/positions.dart';
import 'package:effektio/models/ToDoTask.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoTaskEditor.dart';
import 'package:effektio/widgets/CompletedTaskCard.dart';
import 'package:effektio/widgets/IncompleteTaskCard.dart';
import 'package:flutter/material.dart';

class ToDoTaskView extends StatelessWidget {
  final ToDoTask task;

  const ToDoTaskView({Key? key, required this.task}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
    // return GestureDetector(
    //   onTap: () {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => ToDoTaskEditor(
    //           item: widget,
    //           avatars: avatars,
    //         ),
    //       ),
    //     );
    //   },
    //   child: widget.isCompleted
    //       ? CompletedTaskCard(
    //           title: widget.title,
    //           isCompleted: widget.isCompleted,
    //           dateTime: widget.dateTime,
    //           toggleCompletion: widget.toggleCompletion,
    //           hasMessage: widget.hasMessage,
    //           avatars: avatars)
    //       : IncompleteTaskCard(
    //           title: widget.title,
    //           isCompleted: widget.isCompleted,
    //           dateTime: widget.dateTime,
    //           toggleCompletion: widget.toggleCompletion,
    //           hasMessage: widget.hasMessage,
    //           avatars: avatars),
    // );
  }

  List<ImageProvider<Object>> getMockAvatars(int count) {
    return List.generate(count, (index) {
      int id = Random().nextInt(70);
      return NetworkImage('https://i.pravatar.cc/100?img = ${id.toString()}');
    });
  }
}
