import 'package:flutter/material.dart';

class UserDisplayNameWidget extends StatelessWidget {
  final String displayName;
  final TextStyle? textStyle;

  const UserDisplayNameWidget({
    super.key,
    required this.displayName,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final displayNameTextStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.bold);
    return Text(displayName, style: textStyle ?? displayNameTextStyle);
  }
}
