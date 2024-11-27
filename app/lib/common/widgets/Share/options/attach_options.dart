import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class AttachOptions extends StatelessWidget {
  final String data;

  const AttachOptions({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Attache To',
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 12),
        Wrap(
          children: [
            iconItem('Boost', Atlas.megaphone_thin, boastFeatureColor),
            iconItem('Pin', Atlas.pin, pinFeatureColor),
            iconItem('Event', Atlas.calendar, eventFeatureColor),
            iconItem('TaskList', Atlas.list, taskFeatureColor),
            iconItem('Task', Atlas.list, taskFeatureColor),
            iconItem('Space', Atlas.group_people_arrow_up, Colors.grey),
            iconItem('Chat', Atlas.chats, Colors.brown),
          ],
        ),
      ],
    );
  }

  Widget iconItem(String name, IconData iconData, Color color) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color,
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
              ),
              child: Icon(iconData)),
          SizedBox(height: 6),
          Text(name),
        ],
      ),
    );
  }
}
