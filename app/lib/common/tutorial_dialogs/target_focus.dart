import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

TargetFocus targetFocus({
  required String identify,
  required GlobalKey keyTarget,
  required String contentTitle,
  required String contentDescription,
  String? contentImageUrl,
  IconData? iconData,
  double iconSize = 150,
  ShapeLightFocus? shape,
  double? paddingFocus,
  ContentAlign contentAlign = ContentAlign.bottom,
  AlignmentGeometry? alignSkip,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    shape: shape,
    paddingFocus: paddingFocus,
    alignSkip: alignSkip,
    contents: [
      TargetContent(
        align: contentAlign,
        builder: (context, controller) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (contentImageUrl != null)
                SvgPicture.asset(
                  contentImageUrl,
                  semanticsLabel: 'state',
                  height: 150,
                  width: 150,
                ),
              if (iconData != null)
                Icon(
                  iconData,
                  size: iconSize,
                ),
              if (contentImageUrl != null || iconData != null)
                const SizedBox(height: 50),
              Text(
                contentTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                contentDescription,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          );
        },
      ),
    ],
  );
}
