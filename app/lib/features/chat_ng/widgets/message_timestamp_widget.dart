import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/chat_ng/utils.dart';

class MessageTimestampWidget extends StatelessWidget {
  final int timestamp;

  const MessageTimestampWidget({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final chatTheme = Theme.of(context).chatTheme;
    return Text(
      jiffyMsgTimestamp(context, timestamp),
      style: chatTheme.emptyChatPlaceholderTextStyle.copyWith(fontSize: 12),
    );
  }
}
