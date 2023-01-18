import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter/material.dart';

class TodoTaskEditorModel {

  TodoTaskEditorModel({
    required this.item,
    required this.avatars,
  });

  ToDoTaskItem item;
  List<ImageProvider<Object>> avatars;
}