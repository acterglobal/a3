import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:flutter/material.dart';

class WithSidebar extends StatelessWidget {
  final Widget child;
  final Widget sidebar;
  const WithSidebar({
    super.key,
    required this.child,
    required this.sidebar,
  });

  @override
  Widget build(BuildContext context) {
    final isLarge = context.isLargeScreen;
    if (isLarge) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(flex: 1, child: sidebar),
          Flexible(flex: 2, child: child),
        ],
      );
    }
    return child;
  }
}
