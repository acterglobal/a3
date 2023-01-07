import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/models/ToDoList.dart';
import 'package:flutter/material.dart';

class ToDoListView extends StatelessWidget {
  const ToDoListView({Key? key, required this.controller}) : super(key: key);
  final ToDoController controller;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ToDoList>>(
      future: controller.getTodoList(),
      builder: (BuildContext context, AsyncSnapshot<List<ToDoList>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                heightFactor: MediaQuery.of(context).size.height * 0.02,
                child: const Text(
                  'You do not have any todos yet',
                  style: ToDoTheme.titleTextStyle,
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    color: ToDoTheme.secondaryColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 15.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          buildHeaderContent(
                            snapshot.data![index].name,
                            snapshot.data![index].tags,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load lists due to ${snapshot.error}',
                style: ToDoTheme.taskListTextStyle,
              ),
            );
          }
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildHeaderContent(String title, List<String>? tags) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: ToDoTheme.listTitleTextStyle,
            ),
          ),
          const SizedBox(
            width: 8.0,
          ),
          Wrap(
            direction: Axis.horizontal,
            spacing: 8.0,
            children: List.generate(
              tags!.length,
              (index) => Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: AppCommonTheme.secondaryColor,
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Text(
                  tags[index],
                  style: ToDoTheme.listTagTextStyle,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
