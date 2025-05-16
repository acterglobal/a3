import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/widgets/expect_decryption_failures_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingEncryptionKeyBackupPage extends ConsumerStatefulWidget {
  final VoidCallback callNextPage;

  const OnboardingEncryptionKeyBackupPage({
    super.key,
    required this.callNextPage,
  });

  @override
  ConsumerState<OnboardingEncryptionKeyBackupPage> createState() =>
      _OnboardingEncryptionKeyBackupPageState();
}

class _OnboardingEncryptionKeyBackupPageState
    extends ConsumerState<OnboardingEncryptionKeyBackupPage> {
  final TextEditingController encryptionKeyController = TextEditingController();
  bool _hasText = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    encryptionKeyController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = encryptionKeyController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    encryptionKeyController.removeListener(_onTextChanged);
    encryptionKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildHeadlineText(context),
                      const SizedBox(height: 20),
                      _buildDescriptionText(context),
                      const SizedBox(height: 20),
                      _buildEncryptionKeyInputField(context),
                    ],
                  ),
                ),
                _buildActionButton(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).encryptionKeyBackup,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).encryptionKeyBackupOnboardingDescription,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEncryptionKeyInputField(BuildContext context) {
    final lang = L10n.of(context);
    return TextFormField(
      key: ValueKey(_hasText),
      controller: encryptionKeyController,
      decoration: InputDecoration(
        hintText: lang.encryptionKeyBackup,
        suffixIcon:
            _hasText
                ? IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                  onPressed: () {
                    final text = encryptionKeyController.text;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                )
                : null,
      ),
      validator:
          (val) =>
              val == null || val.trim().isEmpty
                  ? lang.encryptionBackupRecoverProvideKey
                  : null,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
      
            }
          },
          child: Text(lang.next),
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
                  return ExpectDecryptionFailures(callNextPage: () {
                    widget.callNextPage();
                  });
                },
              );
          },
          child: Text(lang.continueWithoutKey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
