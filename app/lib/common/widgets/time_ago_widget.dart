import 'package:dart_date/dart_date.dart';
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
    final originServerDateTime =
        DateTime.fromMillisecondsSinceEpoch(originServerTs, isUtc: true);
    final time = originServerDateTime.toLocal().timeago();
    return Text(
      time,
      style: textStyle ?? Theme.of(context).textTheme.labelMedium,
    );
  }
}
