import 'package:flutter/material.dart';

class WithSidebar extends StatelessWidget {
  final Widget child;
  final Widget sidebar;
  const WithSidebar({Key? key, required this.child, required this.sidebar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770) {
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
      },
    );
  }
}
