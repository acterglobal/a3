import 'package:flutter/material.dart';

class DashedLineVertical extends StatelessWidget {
  final double? height;
  final double dashHeight;
  final double dashSpacing;
  final Color color;

  const DashedLineVertical({
    super.key,
    this.height,
    this.dashHeight = 6,
    this.dashSpacing = 5,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0.5,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(
          dashHeight: dashHeight,
          dashSpacing: dashSpacing,
          color: color,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final double dashHeight;
  final double dashSpacing;
  final Color color;

  _DashedLinePainter({
    required this.dashHeight,
    required this.dashSpacing,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpacing;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 