import 'package:flutter/material.dart';

class DialogPage<T> extends Page<T> {
  final Offset? anchorPoint;
  final Color? barrierColor;
  final bool barrierDismissible;
  final String? barrierLabel;
  final String? label;
  final bool useSafeArea;
  final CapturedThemes? themes;
  final WidgetBuilder builder;

  const DialogPage({
    required this.builder,
    this.anchorPoint,
    this.barrierColor = Colors.black87,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.label,
    this.useSafeArea = true,
    this.themes,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
        context: context,
        settings: this,
        builder: (context) {
          Widget dialogChild = IntrinsicWidth(
            stepWidth: 56.0,
            child: builder(context),
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
          return Dialog(
            child: dialogChild,
          );
        },
        anchorPoint: anchorPoint,
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        useSafeArea: useSafeArea,
        themes: themes,
      );
}
