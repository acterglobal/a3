/// This file is taken from https://github.com/adar2378/tab_indicator_styler and all credits
/// goes to the developer of the library.

import 'package:flutter/material.dart';

class MaterialIndicator extends Decoration {
  final double height;
  final TabPosition tabPosition;
  final double topRightRadius;
  final double topLeftRadius;
  final double bottomRightRadius;
  final double bottomLeftRadius;
  final Color color;
  final double horizontalPadding;
  final PaintingStyle paintingStyle;
  final double strokeWidth;

  const MaterialIndicator({
    this.height = 4,
    this.tabPosition = TabPosition.bottom,
    this.topRightRadius = 5,
    this.topLeftRadius = 5,
    this.bottomRightRadius = 0,
    this.bottomLeftRadius = 0,
    this.color = Colors.black,
    this.horizontalPadding = 0,
    this.paintingStyle = PaintingStyle.fill,
    this.strokeWidth = 2,
  });

  @override
  _CustomPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPainter(
      this,
      onChanged,
      bottomLeftRadius: bottomLeftRadius,
      bottomRightRadius: bottomRightRadius,
      color: color,
      height: height,
      horizontalPadding: horizontalPadding,
      tabPosition: tabPosition,
      topLeftRadius: topLeftRadius,
      topRightRadius: topRightRadius,
      paintingStyle: paintingStyle,
      strokeWidth: strokeWidth,
    );
  }
}

class _CustomPainter extends BoxPainter {
  final MaterialIndicator decoration;
  final double height;
  final TabPosition tabPosition;
  final double topRightRadius;
  final double topLeftRadius;
  final double bottomRightRadius;
  final double bottomLeftRadius;
  final Color color;
  final double horizontalPadding;
  final double strokeWidth;
  final PaintingStyle paintingStyle;

  _CustomPainter(
    this.decoration,
    VoidCallback? onChanged, {
    required this.height,
    required this.tabPosition,
    required this.topRightRadius,
    required this.topLeftRadius,
    required this.bottomRightRadius,
    required this.bottomLeftRadius,
    required this.color,
    required this.horizontalPadding,
    required this.paintingStyle,
    required this.strokeWidth,
  }) : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(horizontalPadding >= 0);
    assert(
      horizontalPadding < configuration.size!.width / 2,
      'Padding must be less than half of the size of the tab',
    );
    assert(height > 0);
    assert(
      strokeWidth >= 0 &&
          strokeWidth < configuration.size!.width / 2 &&
          strokeWidth < configuration.size!.height / 2,
    );

    //offset is the position from where the decoration should be drawn.
    //configuration.size tells us about the height and width of the tab.
    Size mysize =
        Size(configuration.size!.width - (horizontalPadding * 2), height);

    Offset myoffset = Offset(
      offset.dx + (horizontalPadding),
      offset.dy +
          (tabPosition == TabPosition.bottom
              ? configuration.size!.height - height
              : 0),
    );

    final Rect rect = myoffset & mysize;
    final Paint paint = Paint();
    paint.color = color;
    paint.style = paintingStyle;
    paint.strokeWidth = strokeWidth;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        bottomRight: Radius.circular(bottomRightRadius),
        bottomLeft: Radius.circular(bottomLeftRadius),
        topLeft: Radius.circular(topLeftRadius),
        topRight: Radius.circular(topRightRadius),
      ),
      paint,
    );
  }
}

enum TabPosition { top, bottom }
