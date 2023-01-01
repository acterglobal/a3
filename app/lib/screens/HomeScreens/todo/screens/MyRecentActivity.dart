import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class MyRecentActivityScreen extends StatefulWidget {
  const MyRecentActivityScreen({Key? key}) : super(key: key);

  @override
  State<MyRecentActivityScreen> createState() => _MyAssignmentScreenState();
}

class _MyAssignmentScreenState extends State<MyRecentActivityScreen> {
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
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Recent Activity',
                style:
                ToDoTheme.listTitleTextStyle,
              ),
              SizedBox(
                height: 16,
              ),
              Timeline.tileBuilder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                theme: TimelineThemeData(
                  nodePosition: 0,
                  nodeItemOverlap: true,
                  indicatorTheme: IndicatorThemeData(
                    color: ToDoTheme.calendarColor
                  ),
                  connectorTheme: ConnectorThemeData(
                    color: ToDoTheme.calendarColor,
                    thickness: 2.0,
                  ),
                ),
                builder: TimelineTileBuilder.fromStyle(
                  contentsBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Oct 19, 06:30', style: ToDoTheme.listSubtitleTextStyle.copyWith(
                          color: ToDoTheme.inactiveTextColor,
                          fontSize: 13
                        ),),
                        Text('David Chunli posted this ToDo', style: ToDoTheme.listTitleTextStyle,),
                      ],
                    ),
                  ),
                  itemCount: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
