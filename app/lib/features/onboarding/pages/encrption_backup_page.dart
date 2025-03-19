import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';

class EncryptionBackupPage extends ConsumerWidget {
  const EncryptionBackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, lang),
            const SizedBox(height: 16),
            _buildDescription(context, lang),
            const SizedBox(height: 32),
            _buildEncryptionKey(context, ref),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const Spacer(),
            _buildNavigationButtons(context, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, L10n lang) {
    return Text(
      lang.encryptionKeyBackupTitle,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context, L10n lang) {
    return Text(
      lang.encryptionKeyBackupDescription,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEncryptionKey(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        'recoveryKey',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontSize: 16, letterSpacing: 1.2),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildActionButton(icon: Icons.copy, onTap: () {}, context: context),
        const SizedBox(width: 24),
        _buildActionButton(
          icon: Icons.desktop_windows,
          onTap: () {},
          context: context,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNextButton(context, lang),
        const SizedBox(height: 16),
        _buildRemindLaterButton(context, lang),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNextButton(BuildContext context, L10n lang) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(lang.next, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildRemindLaterButton(BuildContext context, L10n lang) {
    return TextButton(
      onPressed: () {},
      child: Text(
        lang.remindMeLater,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Icon(icon),
      ),
    );
  }
}
