import 'package:flutter/material.dart';

class PulsatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Duration duration;
  final Duration delay;

  const PulsatingIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 16,
    this.duration = const Duration(seconds: 1),
    this.delay = const Duration(seconds: 0),
  });

  @override
  State<PulsatingIcon> createState() => _PulsatingIconState();
}

class _PulsatingIconState extends State<PulsatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: 1 + 0.2 * _animation.value, child: child);
      },
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}
