import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';

class MessageTimestampWidget extends StatelessWidget {
  final int timestamp;
  final Color? textColor;
  final bool showDay;

  const MessageTimestampWidget({
    super.key,
    required this.timestamp,
    this.textColor,
    this.showDay = false,
  });

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;

    String formattedTime = jiffyDateTimestamp(
      context,
      timestamp,
      showDay: false,
    );

    return Text(
      formattedTime,
      style: chatTheme.emptyChatPlaceholderTextStyle.copyWith(
        fontSize: 10,
        color: textColor,
      ),
    );
  }
}
