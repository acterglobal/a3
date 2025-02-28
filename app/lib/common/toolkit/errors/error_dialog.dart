import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/bug_report/actions/open_bug_report.dart';
import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:quickalert/models/quickalert_options.dart';
import 'package:quickalert/quickalert.dart';
import 'package:quickalert/widgets/quickalert_buttons.dart';
import 'package:quickalert/widgets/quickalert_container.dart';

class ActerErrorDialog extends StatelessWidget {
  static const retryBtn = Key('error-dialog-retry-btn');

  final Object error;
  final StackTrace? stack;
  final VoidCallback? onRetryTap;

  final String? title;
  final String? text;
  final ErrorTextBuilder? textBuilder;
  final bool includeBugReportButton;

  /// Dialog Border Radius
  final double borderRadius;

  const ActerErrorDialog({
    super.key,
    required this.error,
    this.stack,
    this.onRetryTap,
    this.title,
    this.text,
    this.textBuilder,
    this.includeBugReportButton = true,
    this.borderRadius = 15.0,
  });

  static Future show({
    /// BuildContext
    required BuildContext context,
    required Object error,
    StackTrace? stack,

    /// Title of the dialog
    String? title,

    /// Text of the dialog
    String? text,
    VoidCallback? onRetryTap,
    ErrorTextBuilder? textBuilder,
    bool includeBugReportButton = true,

    /// Dialog Border Radius
    double borderRadius = 15.0,
  }) {
    return showGeneralDialog(
      context: context,
      pageBuilder:
          (context, anim1, __) => ActerErrorDialog(
            error: error,
            stack: stack,
            title: title,
            text: text,
            textBuilder: textBuilder,
            onRetryTap: onRetryTap,
            borderRadius: borderRadius,
            includeBugReportButton: includeBugReportButton,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      content: errorDialog(context),
    );
  }

  Widget errorDialog(BuildContext context) {
    final theme = Theme.of(context);
    final lang = L10n.of(context);
    final err = ErrorCode.guessFromError(error);
    QuickAlertOptions options = QuickAlertOptions(
      title:
          title ??
          switch (err) {
            ErrorCode.notFound => lang.notFound,
            ErrorCode.forbidden => lang.forbidden,
            _ => lang.fatalError,
          },
      text: text ?? textBuilder.map((cb) => cb(error, err)),
      type: switch (err) {
        ErrorCode.notFound ||
        ErrorCode.forbidden ||
        ErrorCode.unknown => QuickAlertType.warning,
        _ => QuickAlertType.error,
      },
      showCancelBtn: true,
      showConfirmBtn: false,
      cancelBtnText: lang.back,
      borderRadius: borderRadius,
    );

    onRetryTap.map((cb) {
      options.showConfirmBtn = true;
      options.confirmBtnColor = theme.primaryColor;
      options.confirmBtnText = lang.retry;
      options.onConfirmBtnTap = cb;
    });

    return _ActerErrorAlert(
      error: error,
      stack: stack,
      options: options,
      includeBugReportButton: includeBugReportButton,
    );
  }
}

class _ActerErrorAlert extends QuickAlertContainer {
  final bool includeBugReportButton;
  final Object error;
  final StackTrace? stack;

  const _ActerErrorAlert({
    required super.options,
    required this.error,
    this.stack,
    this.includeBugReportButton = true,
  });

  @override
  Widget buildButtons() {
    return _ActerErrorActionButtons(options: options);
  }

  @override
  Widget buildHeader(context) {
    final orginalHeader = super.buildHeader(context);
    if (!includeBugReportButton || !isBugReportingEnabled) {
      return orginalHeader;
    }
    return Stack(
      children: [
        orginalHeader,
        Positioned(
          right: 10,
          top: 10,
          child: TextButton(
            child: Text(L10n.of(context).reportBug),
            onPressed: () async {
              final queryParams = {'error': error.toString()};
              stack.map((s) => queryParams['stack'] = s.toString());
              return openBugReport(context, queryParams: queryParams);
            },
          ),
        ),
      ],
    );
  }
}

class _ActerErrorActionButtons extends QuickAlertButtons {
  const _ActerErrorActionButtons({required super.options});

  @override
  Widget buildButton({
    BuildContext? context,
    required bool isOkayBtn,
    required String text,
    VoidCallback? onTap,
  }) {
    final btnText = Text(text, style: defaultTextStyle(isOkayBtn));
    if (isOkayBtn) {
      return buildOkayBtn(context: context, btnText: btnText, onTap: onTap);
    }
    return buildCancelBtn(btnText: btnText, onTap: onTap);
  }

  Widget buildOkayBtn({
    BuildContext? context,
    required Widget btnText,
    VoidCallback? onTap,
  }) {
    return MaterialButton(
      key: ActerErrorDialog.retryBtn,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color:
          options.confirmBtnColor ??
          context.map((ctx) => Theme.of(ctx).primaryColor),
      onPressed: onTap,
      child: Center(
        child: Padding(padding: const EdgeInsets.all(7.5), child: btnText),
      ),
    );
  }

  Widget buildCancelBtn({required Widget btnText, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Center(child: btnText));
  }
}
