import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/deep_linking/parse_acter_uri.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AttachOptions extends StatelessWidget {
  final String link;
  final bool isShowBoostOption;
  final bool isShowPinOption;
  final bool isShowEventOption;
  final bool isShowTaskListOption;
  final bool isShowTaskOption;

  const AttachOptions({
    super.key,
    required this.link,
    this.isShowBoostOption = true,
    this.isShowPinOption = true,
    this.isShowEventOption = true,
    this.isShowTaskListOption = true,
    this.isShowTaskOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final result = parseActerUri(Uri.parse(link));
    final type = result.type;
    final objectType = result.objectPath!.objectType;
    final objectId = result.target;
    final roomId = result.roomId;

    return Wrap(
      children: [
        if (isShowBoostOption)
          attachToItemUI(
            name: lang.boost,
            iconData: Atlas.megaphone_thin,
            color: boastFeatureColor,
            onTap: () {},
          ),
        if (isShowPinOption)
          attachToItemUI(
            name: lang.pin,
            iconData: Atlas.pin,
            color: pinFeatureColor,
            onTap: () {},
          ),
        if (isShowEventOption)
          attachToItemUI(
            name: lang.event,
            iconData: Atlas.calendar,
            color: eventFeatureColor,
            onTap: () {},
          ),
        if (isShowTaskListOption)
          attachToItemUI(
            name: lang.taskList,
            iconData: Atlas.list,
            color: taskFeatureColor,
            onTap: () {},
          ),
        if (isShowTaskOption)
          attachToItemUI(
            name: lang.task,
            iconData: Atlas.list,
            color: taskFeatureColor,
            onTap: () {},
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
