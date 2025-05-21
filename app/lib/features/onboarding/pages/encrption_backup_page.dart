import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/encryption_backup_feature/widgets/encryption_backup_widget.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final log = Logger('a3:onboarding:encryption_backup_page');

class EncryptionBackupPage extends ConsumerStatefulWidget {
  final CallNextPage? callNextPage;
  final String username;
  const EncryptionBackupPage({
    super.key,
    required this.callNextPage,
    required this.username,
  });

  @override
  ConsumerState<EncryptionBackupPage> createState() =>
      _EncryptionBackupPageState();
}

class _EncryptionBackupPageState extends ConsumerState<EncryptionBackupPage> {
  final isEnableNextButton = ValueNotifier<bool>(false);

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Icon(PhosphorIcons.lockKey(), size: 80, color: primaryColor),
                const SizedBox(height: 24),
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildDescription(context),
                const SizedBox(height: 32),
                _buildEncryptionKey(context),
                const SizedBox(height: 32),
                _buildNavigationButtons(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      L10n.of(context).encryptionKeyBackupTitle,
      style: Theme.of(context).textTheme.titleLarge,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      L10n.of(context).encryptionKeyBackupDescription,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEncryptionKey(BuildContext context) {
    final encKey = ref.watch(enableEncrptionBackUpProvider);
    return encKey.when(
      data: (data) {
        return Column(
          children: [
            _buildEncryptionKeyContent(context, data),
            const SizedBox(height: 32),
            PasswordManagerBackupWidget(
              encryptionKey: data,
              onButtonPressed: () {
                isEnableNextButton.value = true;
              },
            ),
          ],
        );
      },
      error:
          (error, stack) => _buildEncryptionKeyError(context, error.toString()),
      loading: () => const Center(child: LinearProgressIndicator()),
    );
  }

  Widget _buildEncryptionKeyContent(BuildContext context, String encKey) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontSize: 16, letterSpacing: 1.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(encKey, style: style, textAlign: TextAlign.center),
    );
  }

  Widget _buildEncryptionKeyError(BuildContext context, String error) {
    final errorColor = Theme.of(context).colorScheme.error;
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: errorColor);
    return Center(
      child: Column(
        children: [
          Text(error, style: style),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: errorColor,
              side: BorderSide(color: errorColor),
            ),
            onPressed: () => ref.invalidate(enableEncrptionBackUpProvider),
            child: Text(L10n.of(context).retry),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) => AutofillGroup(
    onDisposeAction: AutofillContextAction.commit,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNextButton(context),
        const SizedBox(height: 16),
        _buidSkipButton(context),
        const SizedBox(height: 16),

        Visibility(
          // hidden auto save items
          visible: false,
          maintainState: true, // ensure the fields are having state
          child: Column(
            children: [
              TextField(
                controller: usernameController,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                autofillHints: const [AutofillHints.password],
                obscureText: true,
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildNextButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isEnableNextButton,
      builder: (context, isEnabled, _) {
        return ElevatedButton(
          onPressed:
              isEnabled
                  ? () {
                    triggerAutofill(context);
                    widget.callNextPage?.call();
                  }
                  : null,
          child: Text(
            L10n.of(context).next,
            style: const TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buidSkipButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      // we need the context to be within the autofill group
      valueListenable: isEnableNextButton,
      builder:
          (context, _, _) => OutlinedButton(
            onPressed: () {
              triggerAutofill(context);
              // Continue to next page
              widget.callNextPage?.call();
            },
            child: Text(L10n.of(context).skip),
          ),
    );
  }

  void triggerAutofill(BuildContext context) {
    final encKey = ref.read(enableEncrptionBackUpProvider).valueOrNull;
    if (encKey == null) {
      log.warning('No encryption key found');
      return;
    }
    usernameController.text = L10n.of(context).userRecoveryKey(widget.username);
    passwordController.text = encKey;
    TextInput.finishAutofillContext(shouldSave: true);
  }
}
