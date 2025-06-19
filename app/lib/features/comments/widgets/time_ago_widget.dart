import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final originServerDateTime = DateTime.fromMillisecondsSinceEpoch(
      originServerTs,
      isUtc: true,
    ).toLocal();
    final time = DateFormat('hh:mm a').format(originServerDateTime);
    return Text(
      time,
      style: textStyle ?? Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.surfaceTint),
    );
  }
}
