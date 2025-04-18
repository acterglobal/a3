import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class DottedBorderWidget extends StatelessWidget {
  final Widget child;
  final Color? color;

  const DottedBorderWidget({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: color ?? Theme.of(context).colorScheme.onSurface,
      strokeWidth: 2,
      borderType: BorderType.RRect,
      radius: const Radius.circular(10),
      dashPattern: const [10, 7],
      child: child,
    );
  }
}
