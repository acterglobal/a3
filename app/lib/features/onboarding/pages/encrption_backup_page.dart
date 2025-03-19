import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EncryptionBackupPage extends ConsumerWidget {
  const EncryptionBackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildDescription(context),
            const SizedBox(height: 32),
            _buildEncryptionKey(context, ref),
            const SizedBox(height: 32),
            _buildActionButtons(context),
            const Spacer(),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Encryption Key Backup',
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'Acter is End-2-End-Encrypted: only your devices can decrypt the messages. '
      'To provide an additional safety-net for you, there is an encrypted backup '
      'of your keys stored on our services. To access it you will need the '
      'following key. Store it safely!',
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

  Widget _buildNavigationButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNextButton(context),
        const SizedBox(height: 16),
        _buildRemindLaterButton(context),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      child: const Text('Next', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildRemindLaterButton(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        'Remind me later',
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
