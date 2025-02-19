import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AttachOptions extends StatelessWidget {
  final String? sectionTitle;
  final GestureTapCallback? onTapBoost;
  final GestureTapCallback? onTapPin;
  final GestureTapCallback? onTapEvent;
  final GestureTapCallback? onTapTaskList;
  final GestureTapCallback? onTapTaskItem;

  const AttachOptions({
    super.key,
    this.sectionTitle,
    this.onTapBoost,
    this.onTapPin,
    this.onTapEvent,
    this.onTapTaskList,
    this.onTapTaskItem,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sectionTitle != null) ...[
          Row(
            children: [
              Divider(indent: 0),
              Text(
                sectionTitle!,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Expanded(child: Divider(indent: 20)),
            ],
          ),
          SizedBox(height: 12),
        ],
        Wrap(
          children: [
            if (onTapBoost != null)
              attachToItemUI(
                name: lang.newBoost,
                iconData: Atlas.megaphone_thin,
                color: boastFeatureColor,
                onTap: onTapBoost,
              ),
            if (onTapPin != null)
              attachToItemUI(
                name: lang.pin,
                iconData: Atlas.pin,
                color: pinFeatureColor,
                onTap: onTapPin,
              ),
            if (onTapEvent != null)
              attachToItemUI(
                name: lang.event,
                iconData: Atlas.calendar,
                color: eventFeatureColor,
                onTap: onTapEvent,
              ),
            if (onTapTaskList != null)
              attachToItemUI(
                name: lang.taskList,
                iconData: Atlas.list,
                color: taskFeatureColor,
                onTap: onTapTaskList,
              ),
            if (onTapTaskItem != null)
              attachToItemUI(
                name: lang.task,
                iconData: Atlas.list,
                color: taskFeatureColor,
                onTap: onTapTaskItem,
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
                color: color.withValues(alpha:0.3),
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
            Text(name, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
