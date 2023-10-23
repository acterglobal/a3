import 'dart:core';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailAddressCard extends ConsumerWidget {
  final String emailAddress;
  final bool isConfirmed;

  const EmailAddressCard({
    Key? key,
    required this.emailAddress,
    required this.isConfirmed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
      child: ListTile(
        leading: isConfirmed
            ? Icon(
                Atlas.envelope_check_thin,
                color: Theme.of(context).colorScheme.success,
              )
            : const Icon(
                Atlas.envelope_minus_thin,
              ),
        title: Text(emailAddress),
        trailing: isConfirmed
            ? PopupMenuButton(
                itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
                  PopupMenuItem(
                    onTap: () => onUnregister(ctx, ref),
                    child: Row(
                      children: [
                        const Icon(Atlas.trash_can_thin),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Remove',
                            style: Theme.of(ctx).textTheme.labelSmall,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: 80,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => alreadyConfirmedAddress(context, ref),
                      icon: const Icon(Atlas.envelope_check_thin),
                    ),
                    PopupMenuButton(
                      itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () => alreadyConfirmedAddress(context, ref),
                          child: const Row(
                            children: [
                              Icon(Atlas.envelope_check_thin),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Already confirmed'),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => confirmationTokenAddress(context, ref),
                          child: const Row(
                            children: [
                              Icon(Atlas.passcode_thin),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('Confirm with Token'),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => onUnregister(ctx, ref),
                          child: Row(
                            children: [
                              const Icon(Atlas.trash_can_thin),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  'Remove',
                                  style: Theme.of(ctx).textTheme.labelSmall,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void onUnregister(BuildContext context, WidgetRef ref) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => DefaultDialog(
        title: const Text(
          'Are you sure you want to unregister this email address? This action cannot be undone.',
        ),
        actions: <Widget>[
          DefaultButton(
            onPressed: () => Navigator.of(
              context,
              rootNavigator: true,
            ).pop(),
            title: 'No',
            isOutlined: true,
          ),
          DefaultButton(
            onPressed: () async {
              final client = ref.read(clientProvider);
              final manager = client!.threePidManager();
              await manager.removeEmailAddress(emailAddress);
              ref.invalidate(emailAddressesProvider);

              if (!context.mounted) {
                return;
              }
              Navigator.of(context, rootNavigator: true).pop();
            },
            title: 'Yes',
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> alreadyConfirmedAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final client = ref.read(clientProvider);
    final manager = client!.threePidManager();
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PasswordConfirm(),
    );
    if (newValue != null) {
      EasyLoading.show(status: 'Trying to confirm token');
      try {
        await manager.tryConfirmEmailStatus(emailAddress, newValue);
        ref.invalidate(emailAddressesProvider);
        EasyLoading.showSuccess('Looks good. Address confirmed.');
      } catch (e) {
        EasyLoading.showError(
          'Failed to confirm token: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> confirmationTokenAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final client = ref.read(clientProvider);
    final manager = client!.threePidManager();
    final newValue = await showDialog<EmailConfirm>(
      context: context,
      builder: (BuildContext context) => const TokenConfirm(),
    );
    if (newValue != null) {
      EasyLoading.show(status: 'Trying to confirm token');
      try {
        await manager.submitTokenFromEmail(
          emailAddress,
          newValue.token,
          newValue.password,
        );
        ref.invalidate(emailAddressesProvider);
        EasyLoading.showSuccess('Looks good');
      } catch (e) {
        EasyLoading.showError(
          'Failed to confirm token: $e',
          duration: const Duration(seconds: 3),
        );
      }
    }
  }
}

class EmailConfirm {
  String token;
  String password;

  EmailConfirm(this.token, this.password);
}

class PasswordConfirm extends StatefulWidget {
  const PasswordConfirm({Key? key}) : super(key: key);

  @override
  State<PasswordConfirm> createState() => _PasswordConfirmState();
}

class _PasswordConfirmState extends State<PasswordConfirm> {
  final TextEditingController newPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Need your password to confirm ',
      ), // The token-reset path is just the process by which control over that email address is confirmed.
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: 'Your Password',
                  suffixIcon: IconButton(
                    onPressed: togglePassword,
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !passwordVisible,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => onSubmit(context),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(context, newPassword.text);
  }
}

class TokenConfirm extends StatefulWidget {
  const TokenConfirm({Key? key}) : super(key: key);

  @override
  State<TokenConfirm> createState() => _TokenConfirmState();
}

class _TokenConfirmState extends State<TokenConfirm> {
  final TextEditingController tokenField = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Confirmation Token',
      ), // The token-reset path is just the process by which control over that email address is confirmed.
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: tokenField,
                decoration: const InputDecoration(hintText: 'Token'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: 'Your Password',
                  suffixIcon: IconButton(
                    onPressed: togglePassword,
                    icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !passwordVisible,
                enableSuggestions: false,
                autocorrect: false,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => onSubmit(context),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void togglePassword() {
    setState(() {
      passwordVisible = !passwordVisible;
    });
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      customMsgSnackbar(context, 'Token and password must be provided');
      return;
    }
    // user can reset password under the same email address
    final result = EmailConfirm(tokenField.text, newPassword.text);
    Navigator.pop(context, result);
  }
}
