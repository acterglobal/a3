import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/onboarding/widgets/expect_decryption_failures_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MissingEncryptionBackupPage extends ConsumerWidget {
  final VoidCallback callNextPage;
  const MissingEncryptionBackupPage({
    super.key,
    required this.callNextPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeadlineText(context),
                    const SizedBox(height: 40),
                    _buildImage(context),
                    const SizedBox(height: 20),
                    _buildDescriptionText(context),
                  ],
                ),
              ),
              _buildActionButton(context, ref),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
   final theme = Theme.of(context);
    return Text(
      L10n.of(context).missingEncryptionBackup,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildImage(BuildContext context) {
    return Icon(
          PhosphorIcons.warning(),
          color: warningColor,
          size: 100,
        );
  }

  Widget _buildDescriptionText(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          L10n.of(context).missingEncryptionBackupDescription1,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          L10n.of(context).missingEncryptionBackupDescription2,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          L10n.of(context).missingEncryptionBackupDescription3,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            ref.invalidate(backupStateProvider);
          },
          child: Text(lang.tryAgain),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            showModalBottomSheet(
                showDragHandle: true,
                context: context,
                useSafeArea: true,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                builder: (context) {
                  return ExpectDecryptionFailures(callNextPage: callNextPage);
                },
              );
          },
          child: Text(lang.continueWithoutKey),
        ),
      ],
    );
  }
}
