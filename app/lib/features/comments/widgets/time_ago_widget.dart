import 'package:dart_date/dart_date.dart';
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
    );
    final now = DateTime.now();
    final difference = now.difference(originServerDateTime.toLocal());
    
    String time;
    if (difference.inDays >= 30) {
      // Show actual date and time for dates older than a month
      time = DateFormat('MMM d, yyyy h:mm a').format(originServerDateTime.toLocal());
    } else {
      time = originServerDateTime.toLocal().timeago();
    }
    
    return Text(
      time,
      style: textStyle ?? Theme.of(context).textTheme.labelMedium,
    );
  }
}
