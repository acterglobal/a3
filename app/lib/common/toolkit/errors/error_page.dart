import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:flutter/material.dart';

/// ErrorPage shows a full-screen error to the user (covering other internal errors)
///
class ErrorPage extends StatelessWidget {
  static const dialogKey = Key('error-page-dialog');

  /// Put this widget in the Background of the screen to give context
  final Widget background;
  final Object error;
  final StackTrace stack;
  final VoidCallback? onRetryTap;

  final String? title;
  final String? text;
  final ErrorTextBuilder? textBuilder;
  final bool includeBugReportButton;

  /// Dialog Border Radius
  final double borderRadius;

  const ErrorPage({
    super.key,
    required this.background,
    required this.error,
    required this.stack,
    this.title,
    this.text,
    this.textBuilder,
    this.onRetryTap,
    this.borderRadius = 15.0,
    this.includeBugReportButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        background,
        ActerErrorDialog(
          key: dialogKey,
          error: error,
          stack: stack,
          includeBugReportButton: includeBugReportButton,
          text: text,
          textBuilder: textBuilder,
          title: title,
          onRetryTap: onRetryTap,
          borderRadius: borderRadius,
        ),
      ],
    );
  }
}
