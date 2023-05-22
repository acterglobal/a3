import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideSheetPage<T> extends CustomTransitionPage<T> {
  final Offset? anchorPoint;
  final String? label;
  final bool useSafeArea;
  final CapturedThemes? themes;

  const SideSheetPage({
    required super.transitionsBuilder,
    required super.child,
    this.anchorPoint,
    super.barrierColor = Colors.black87,
    super.barrierDismissible = true,
    super.barrierLabel,
    super.transitionDuration = const Duration(milliseconds: 500),
    this.label,
    this.useSafeArea = true,
    this.themes,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => RawDialogRoute<T>(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          final totalWidth = MediaQuery.of(context).size.width;
          double width = MediaQuery.of(context).size.width / 1.4;
          if (width < 300) {
            width = totalWidth * 0.95;
          } else if (width > 450) {
            width = 450;
          }

          Widget dialogChild = IntrinsicWidth(
            stepWidth: 56.0,
            child: child,
          );
          if (label != null) {
            dialogChild = Semantics(
              scopesRoute: true,
              explicitChildNodes: true,
              namesRoute: true,
              label: label,
              child: dialogChild,
            );
          }
          return Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: double.infinity,
              width: width,
              child: dialogChild,
            ),
          );
        },
        settings: this,
        transitionBuilder: transitionsBuilder,
        anchorPoint: anchorPoint,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
      );
}
