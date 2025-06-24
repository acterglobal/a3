import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';

class TimeAgoWidget extends StatelessWidget {
  final int originServerTs;
  final TextStyle? textStyle;

  const TimeAgoWidget({
    super.key,
    required this.originServerTs,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final time = formatTimeFromTimestamp(originServerTs);
    return Text(
      time,
      style: textStyle ?? Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.surfaceTint),
    );
  }
}
