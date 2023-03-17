import 'package:acter/common/themes/seperated_themes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({Key? key}) : super(key: key);

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCommonTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppCommonTheme.backgroundColorLight,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Atlas.arrow_left_circle,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'My assignments',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemBuilder: (context, index) {
            return Card(
              color: AppCommonTheme.backgroundColorLight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oct 19 at 3:36am',
                      style: ToDoTheme.descriptionTextStyle.copyWith(
                        color: ToDoTheme.calendarColor,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'Web application on design',
                      style: ToDoTheme.listTitleTextStyle,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Owner: ',
                              style: ToDoTheme.listSubtitleTextStyle
                                  .copyWith(color: ToDoTheme.calendarColor),
                            ),
                            Text(
                              'David Chunli',
                              style: ToDoTheme.listSubtitleTextStyle
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: const [
                            Text(
                              'View Assigned',
                              style: ToDoTheme.listSubtitleTextStyle,
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Icon(
                              Atlas.arrow_right_circle,
                              color: ToDoTheme.secondaryTextColor,
                              size: 18,
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
