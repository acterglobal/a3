import 'package:flutter/material.dart';

class IconMessageWidget extends StatelessWidget {
  final bool isDM;
  final String? senderName;
  final String? message;
  final IconData icon;
  final TextStyle? textStyle;
  const IconMessageWidget({
    super.key,
    this.senderName,
    this.message,
    this.isDM = false,
    required this.icon,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bodySmallTextStyle = Theme.of(context).textTheme.bodySmall;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (senderName != null && !isDM)
          Text('$senderName : ', style: textStyle),
        Icon(icon, size: 14, color: textStyle?.color),
        const SizedBox(width: 4),
        Text(message ?? '', style: textStyle ?? bodySmallTextStyle),
      ],
    );
  }
}
