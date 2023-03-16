import 'package:acter/common/themes/seperated_themes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class RecentActivityPage extends StatefulWidget {
  const RecentActivityPage({Key? key}) : super(key: key);

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Recent Activity',
                style: ToDoTheme.listTitleTextStyle,
              ),
              const SizedBox(
                height: 16,
              ),
              Timeline.tileBuilder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                theme: TimelineThemeData(
                  nodePosition: 0,
                  nodeItemOverlap: true,
                  indicatorTheme: const IndicatorThemeData(
                    color: ToDoTheme.calendarColor,
                  ),
                  connectorTheme: const ConnectorThemeData(
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
                        Text(
                          'Oct 19, 06:30',
                          style: ToDoTheme.listSubtitleTextStyle.copyWith(
                            color: ToDoTheme.inactiveTextColor,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'David Chunli posted this ToDo',
                          style: ToDoTheme.listTitleTextStyle,
                        ),
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
