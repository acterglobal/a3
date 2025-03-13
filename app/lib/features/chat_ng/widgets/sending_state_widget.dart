import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/error_dialog.dart';
import 'package:acter/common/toolkit/widgets/pulsating_icon.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show EventSendState;
import 'package:flutter/material.dart';

class SendingStateWidget extends StatelessWidget {
  final EventSendState state;
  final bool showSentIconOnUnknown;

  const SendingStateWidget({
    super.key,
    required this.state,
    this.showSentIconOnUnknown = false,
  });

  @override
  Widget build(BuildContext context) => switch (state.state()) {
    'NotSentYet' => PulsatingIcon(
      icon: Icons.send,
      color: Theme.of(context).colorScheme.onSecondary,
    ),
    'SendingFailed' => _buildSendingFailed(context),
    'Sent' => _buildSentIcon(context),
    _ =>
      showSentIconOnUnknown ? _buildSentIcon(context) : const SizedBox.shrink(),
  };

  Widget _buildSentIcon(BuildContext context) =>
      Icon(Icons.check, color: Theme.of(context).colorScheme.primary);

  Widget _buildSendingFailed(BuildContext context) =>
      ActerInlineTextButton.icon(
        onPressed:
            () => ActerErrorDialog.show(
              context: context,
              error: state.error() ?? 'Error sending message',
              title: L10n.of(context).chatSendingFailed,
              onRetryTap: () {
                state.abort();
              },
              includeBugReportButton: false,
            ),
        icon: const Icon(Icons.error),
        label: Text(L10n.of(context).chatSendingFailed),
      );
}
