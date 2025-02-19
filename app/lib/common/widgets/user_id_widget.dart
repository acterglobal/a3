import 'package:flutter/material.dart';

class UserIdWidget extends StatelessWidget {
  final String userId;
  final TextStyle? textStyle;

  const UserIdWidget({
    super.key,
    required this.userId,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final userNameTextStyle = Theme.of(context).textTheme.labelMedium;
    return Text(userId, style: textStyle ?? userNameTextStyle);
  }
}
