import 'dart:math';

import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ToDoTaskAssignScreen extends StatelessWidget {
  final List<ImageProvider<Object>> avatars;
  final _controller = TextEditingController();

  ToDoTaskAssignScreen({
    Key? key,
    required this.avatars,
  }) : super(key: key);

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
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(overscroll: false),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 40,
                  margin: const EdgeInsets.only(top: 20, right: 16, left: 16),
                  decoration: BoxDecoration(
                    color: ToDoTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 42),
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              cursorColor: Colors.grey,
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: 'Search User',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                    title: const Text(
                      'John Doe',
                      style: ToDoTheme.roleNameTextStyle,
                    ),
                    trailing: Text(
                      taskRole[Random().nextInt(taskRole.length)],
                      style: ToDoTheme.roleTextStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: ToDoTheme.secondaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Someone not in the list? Just Invite them',
                  style: ToDoTheme.taskTitleTextStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                InkWell(
                  onTap: (){
                    showDialogBox(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppCommonTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.group, color: ToDoTheme.primaryTextColor,),
                        const SizedBox(
                          width: 8.0,
                        ),
                        Text('Invite Members',
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  showDialogBox(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: ToDoTheme.backgroundGradientColor,
          child: Wrap(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Invite Friends',
                        style: ToDoTheme.titleTextStyle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        'You can invite your friends to ToDo today via',
                        textAlign: TextAlign.center,
                        style: ToDoTheme.subtitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                            fontSize: 15,),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Column(
                        children: [
                          buildDivider(),
                          Text('Whatsapp', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                          buildDivider(),
                          Text('Email', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                          buildDivider(),
                          Text('SMS', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                          buildDivider(),
                          Text('Invitation Link', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16)),
                          buildDivider(),
                          GestureDetector(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Text('Cancel', style : ToDoTheme.titleTextStyle.copyWith(fontSize: 16, color: Colors.red)))
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        height: 2,
        indent: 0,
        endIndent: 0,
        color: Colors.grey,
      ),
    );
  }
}
