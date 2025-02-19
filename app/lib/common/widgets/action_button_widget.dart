import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Color color;
  final EdgeInsets? padding;
  final VoidCallback? onPressed;

  const ActionButtonWidget({
    super.key,
    required this.title,
    required this.iconData,
    required this.color,
    this.padding,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: TextButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(100)),
          ),
          child: Icon(iconData, size: 14),
        ),
        label: Text(title),
      ),
    );
  }
}
