import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';

class WithSidebar extends StatelessWidget {
  final Widget child;
  final Widget sidebar;
  final bool preferSidebar;
  const WithSidebar({
    Key? key,
    required this.child,
    required this.sidebar,
    this.preferSidebar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770 && isDesktop) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(flex: 1, child: sidebar),
              Flexible(flex: 2, child: child),
            ],
          );
        }
        return preferSidebar ? sidebar : child;
      },
    );
  }
}
