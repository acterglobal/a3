import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

/// InlineErrorButton for text inlined actions
///
/// This is a ErrorButton that highlights the given text using the
/// `theme.inlineErrorTheme`. Thus this is super useful if you have some text
/// and want a specific part of it to be highlighted to the user indicating
/// it has an action. See [ErrorButton] for options.
class ActerInlineErrorButton extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  final VoidCallback? onRetryTap;
  final Icon? icon;

  final String? dialogTitle;
  final String? text;
  final ErrorTextBuilder? textBuilder;
  final bool includeBugReportButton;

  const ActerInlineErrorButton({
    super.key,
    required this.error,
    this.icon,
    this.stack,
    this.dialogTitle,
    this.text,
    this.textBuilder,
    this.onRetryTap,
    this.includeBugReportButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return icon.map((icn) => _buildWithIcon(context, icn)) ??
        TextButton(
          onPressed: () => ActerErrorDialog.show(
            context: context,
            error: error,
            stack: stack,
            title: dialogTitle,
            text: text,
            textBuilder: textBuilder,
            onRetryTap: onRetryTap.map(
              (cb) => () {
                cb();
                Navigator.pop(context);
              },
            ),
            includeBugReportButton: includeBugReportButton,
          ),
          child: Text(L10n.of(context).fatalError),
        );
  }

  const ActerInlineErrorButton.icon({
    super.key,
    required this.error,
    this.stack,
    required this.icon,
    this.dialogTitle,
    this.text,
    this.textBuilder,
    this.onRetryTap,
    this.includeBugReportButton = true,
  });

  Widget _buildWithIcon(BuildContext context, Icon icn) {
    return IconButton(
      icon: icn,
      onPressed: () => ActerErrorDialog.show(
        context: context,
        error: error,
        stack: stack,
        title: dialogTitle,
        text: text,
        textBuilder: textBuilder,
        onRetryTap: onRetryTap.map(
          (cb) => () {
            cb();
            Navigator.pop(context);
          },
        ),
        includeBugReportButton: includeBugReportButton,
      ),
    );
  }
}
