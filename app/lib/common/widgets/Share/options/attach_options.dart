import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AttachOptions extends StatelessWidget {
  final String data;

  const AttachOptions({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lang.attachedTo,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 12),
        Wrap(
          children: [
            attachToItemUI(
              name: lang.boost,
              iconData: Atlas.megaphone_thin,
              color: boastFeatureColor,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.pin,
              iconData: Atlas.pin,
              color: pinFeatureColor,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.event,
              iconData: Atlas.calendar,
              color: eventFeatureColor,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.taskList,
              iconData: Atlas.list,
              color: taskFeatureColor,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.tasks,
              iconData: Atlas.list,
              color: taskFeatureColor,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.space,
              iconData: Atlas.group_people_arrow_up,
              color: Colors.grey,
              onTap: () {},
            ),
            attachToItemUI(
              name: lang.chat,
              iconData: Atlas.chats,
              color: Colors.brown,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget attachToItemUI({
    required String name,
    required IconData iconData,
    required Color color,
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
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
              child: Icon(iconData),
            ),
            SizedBox(height: 6),
            Text(name),
          ],
        ),
      ),
    );
  }
}
