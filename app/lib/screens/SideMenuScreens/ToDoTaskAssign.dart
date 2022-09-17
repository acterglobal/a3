import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/separatedThemes.dart';
import 'package:flutter/material.dart';

class ToDoTaskAssignScreen extends StatelessWidget {
  const ToDoTaskAssignScreen({Key? key, required this.avatars})
      : super(key: key);
  final List<ImageProvider<Object>> avatars;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToDoTheme.backgroundGradientColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ToDoTheme.secondaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ToDoTheme.primaryTextColor,
        ),
        title: const Text('List Members', style: ToDoTheme.listTitleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: ToDoTheme.primaryTextColor,
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    'List Members',
                    style: ToDoTheme.listMemberTextStyle,
                  ),
                  Container(
                    height: 5,
                    width: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ToDoTheme.primaryTextColor,
                    ),
                  ),
                  Text(
                    '${avatars.length}',
                    style: ToDoTheme.subtitleTextStyle,
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: avatars.length,
              itemBuilder: (BuildContext context, int index) => ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundImage: avatars[index],
                ),
                title:
                    const Text('John Doe', style: ToDoTheme.roleNameTextStyle),
                trailing: Text(
                  taskRole[Random().nextInt(taskRole.length)],
                  style: ToDoTheme.roleTextStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
