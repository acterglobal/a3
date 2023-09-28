import 'dart:ui';

import 'package:flutter/material.dart';

// gives frost (blurred) effect to widget.
class FrostEffect extends StatelessWidget {
  final double? widgetWidth;
  final Widget child;
  const FrostEffect({
    super.key,
    this.widgetWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: ClipRect(
        child: SizedBox(
          width: widgetWidth ?? size.width,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 100.0,
              sigmaY: 100.0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
