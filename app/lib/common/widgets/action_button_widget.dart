import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  final String title;
  final IconData iconData;
  final Color color;
  final VoidCallback? onPressed;

  const ActionButtonWidget({
    super.key,
    required this.title,
    required this.iconData,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
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
    );
  }
}
