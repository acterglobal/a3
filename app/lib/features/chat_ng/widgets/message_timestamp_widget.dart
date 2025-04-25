import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class MessageTimestampWidget extends StatelessWidget {
  final int timestamp;

  const MessageTimestampWidget({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;

    final jiffyTime = Jiffy.parseFromMillisecondsSinceEpoch(timestamp);

    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    String formattedTime;

    if (use24HourFormat) {
      formattedTime = jiffyTime.Hm;
    } else {
      formattedTime = jiffyTime.jm;
    }
    return Text(
      formattedTime,
      style: chatTheme.emptyChatPlaceholderTextStyle.copyWith(fontSize: 12),
    );
  }
}
