import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EmailAddressCard extends ConsumerWidget {
  final String emailAddress;
  final bool isConfirmed;

  const EmailAddressCard({
    super.key,
    required this.emailAddress,
    required this.isConfirmed,
  });

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
            : const Icon(Atlas.envelope_minus_thin),
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
                            L10n.of(context).remove,
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
                child: Wrap(
                  children: [
                    IconButton(
                      onPressed: () => alreadyConfirmedAddress(context, ref),
                      icon: const Icon(Atlas.envelope_check_thin),
                    ),
                    PopupMenuButton(
                      itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () => alreadyConfirmedAddress(context, ref),
                          child: Row(
                            children: [
                              const Icon(Atlas.envelope_check_thin),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(L10n.of(context).alreadyConfirmed),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => confirmationTokenAddress(context, ref),
                          child: Row(
                            children: [
                              const Icon(Atlas.passcode_thin),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(L10n.of(context).confirmWithToken),
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
                                  L10n.of(context).remove,
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
        title: Text(L10n.of(context).areYouSureYouWantToUnregisterEmailAddress),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).no),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              final client = ref.read(alwaysClientProvider);
              final manager = client.threePidManager();
              await manager.removeEmailAddress(emailAddress);
              ref.invalidate(emailAddressesProvider);

              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: Text(L10n.of(context).yes),
          ),
        ],
      ),
    );
  }

  Future<void> alreadyConfirmedAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final client = ref.read(alwaysClientProvider);
    final manager = client.threePidManager();
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PasswordConfirm(),
    );
    if (!context.mounted) return;
    if (newValue == null) return;
    EasyLoading.show(status: L10n.of(context).tryingToConfirmToken);
    try {
      await manager.tryConfirmEmailStatus(emailAddress, newValue);
      ref.invalidate(emailAddressesProvider);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).looksGoodAddressConfirmed);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToConfirmToken(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> confirmationTokenAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final client = ref.read(alwaysClientProvider);
    final manager = client.threePidManager();
    final newValue = await showDialog<EmailConfirm>(
      context: context,
      builder: (BuildContext context) => const TokenConfirm(),
    );
    if (!context.mounted) return;
    if (newValue == null) return;
    EasyLoading.show(status: L10n.of(context).tryingToConfirmToken);
    try {
      final result = await manager.submitTokenFromEmail(
        emailAddress,
        newValue.token,
        newValue.password,
      );
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      if (result) {
        ref.invalidate(emailAddressesProvider);
        EasyLoading.showToast(L10n.of(context).looksGoodAddressConfirmed);
      } else {
        EasyLoading.showError(
          L10n.of(context).invalidTokenOrPassword,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToConfirmToken(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class EmailConfirm {
  String token;
  String password;

  EmailConfirm(this.token, this.password);
}

class PasswordConfirm extends StatefulWidget {
  const PasswordConfirm({super.key});

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
      title: Text(L10n.of(context).needYourPasswordToConfirm),
      // The token-reset path is just the process by which control over that email address is confirmed.
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
                  hintText: L10n.of(context).yourPassword,
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
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => onSubmit(context),
          child: Text(L10n.of(context).submit),
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
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, newPassword.text);
  }
}

class TokenConfirm extends StatefulWidget {
  const TokenConfirm({super.key});

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
      title: Text(L10n.of(context).confirmationToken),
      // The token-reset path is just the process by which control over that email address is confirmed.
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: tokenField,
                decoration: InputDecoration(hintText: L10n.of(context).token),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: L10n.of(context).yourPassword,
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
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => onSubmit(context),
          child: Text(L10n.of(context).submit),
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
      EasyLoading.showError(
        L10n.of(context).tokenAndPasswordMustBeProvided,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    // user can reset password under the same email address
    final result = EmailConfirm(tokenField.text, newPassword.text);
    Navigator.pop(context, result);
  }
}
