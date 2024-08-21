import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_options.dart';
import 'package:quickalert/quickalert.dart';
import 'package:quickalert/widgets/quickalert_container.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum ErrorCode {
  notFound,
  other,
}

ErrorCode _guessError(Object error) {
  final errorStr = error.toString();
  // yay, string-based error guessing!
  if (errorStr.contains('not found')) {
    return ErrorCode.notFound;
  }
  return ErrorCode.other;
}

/// ErrorPage shows a full-screen error to the user (covering other internal errors)
///
class ErrorPage extends StatelessWidget {
  /// Put this widget in the Background of the screen to give context
  final Widget background;
  final Object error;
  final StackTrace stack;
  final VoidCallback? onRetryTap;

  final String? title;
  final String? text;
  final String Function(Object error)? textBuilder;

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
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        background,
        AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          content: errorDialog(context),
        ),
      ],
    );
  }

  Widget errorDialog(BuildContext context) {
    final theme = Theme.of(context);
    final lang = L10n.of(context);
    final err = _guessError(error);
    QuickAlertOptions options = QuickAlertOptions(
      title: title ??
          switch (err) {
            ErrorCode.notFound => lang.notFound,
            _ => lang.fatalError,
          },
      text: text ?? (textBuilder != null ? textBuilder!(error) : null),
      type: switch (err) {
        ErrorCode.notFound => QuickAlertType.warning,
        _ => QuickAlertType.error,
      },
      showCancelBtn: true,
      showConfirmBtn: false,
      cancelBtnText: lang.back,
      borderRadius: borderRadius,
    );
    if (onRetryTap != null) {
      options.showConfirmBtn = true;
      options.confirmBtnColor = theme.primaryColor;
      options.confirmBtnText = lang.retry;
      options.onConfirmBtnTap = () {
        onRetryTap!();
      };
    }

    return _ActerErrorAlert(
      options: options,
    );
  }
}

class _ActerErrorAlert extends QuickAlertContainer {
  const _ActerErrorAlert({required super.options});
}
