import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
  AlignmentGeometry? alignSkip = Alignment.topRight,
  bool isFirst = false,
  bool isLast = false,
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isFirst)
                    TextButton(
                      onPressed: () => controller.previous(),
                      child: Text(L10n.of(context).previous),
                    )
                  else
                    const Spacer(),
                  TextButton(
                    onPressed: () => controller.next(),
                    child: Text(
                      isLast ? L10n.of(context).finish : L10n.of(context).next,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}
