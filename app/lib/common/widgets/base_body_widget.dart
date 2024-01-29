import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:flutter/material.dart';

/// Reusable base body widget.
class BaseBody extends StatelessWidget {
  final Widget child;

  const BaseBody({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: primaryGradient,
      ),
      child: child,
    );
  }
}
