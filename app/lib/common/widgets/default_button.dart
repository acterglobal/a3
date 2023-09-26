import 'package:flutter/material.dart';

/// Reusable button widget.
class DefaultButton extends StatelessWidget {
  final void Function()? onPressed;
  // Optional styling.
  final ButtonStyle? style;
  // Whether button should be outlined.
  final bool? isOutlined;
  final String title;

  const DefaultButton({
    Key? key,
    required this.onPressed,
    required this.title,
    this.isOutlined = false,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isOutlined!
        ? OutlinedButton(
            style: style,
            onPressed: onPressed,
            child: Text(title),
          )
        : ElevatedButton(
            style: style,
            onPressed: onPressed,
            child: Text(
              title,
            ),
          );
  }
}
