import 'package:flutter/material.dart';

class DragHandleWidget extends StatelessWidget {
  final double? width;
  final Color? color;

  const DragHandleWidget({super.key, this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      width: width ?? 40,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        borderRadius: const BorderRadius.all(Radius.circular(30.0)),
      ),
    );
  }
}
