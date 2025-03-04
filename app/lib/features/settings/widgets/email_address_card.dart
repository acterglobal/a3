import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::email_address_card');

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
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
      child: ListTile(
        leading:
            isConfirmed
                ? Icon(
                  Atlas.envelope_check_thin,
                  color: Theme.of(context).colorScheme.success,
                )
                : const Icon(Atlas.envelope_minus_thin),
        title: Text(emailAddress),
        trailing:
            isConfirmed
                ? PopupMenuButton(
                  itemBuilder:
                      (context) => <PopupMenuEntry>[
                        PopupMenuItem(
                          onTap: () => onUnregister(context, ref),
                          child: Row(
                            children: [
                              const Icon(Atlas.trash_can_thin),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  lang.remove,
                                  style: textTheme.labelSmall,
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
                        key: Key('$emailAddress-already-confirmed-btn'),
                        onPressed: () => alreadyConfirmedAddress(context, ref),
                        icon: const Icon(Atlas.envelope_check_thin),
                      ),
                      PopupMenuButton(
                        itemBuilder:
                            (context) => <PopupMenuEntry>[
                              PopupMenuItem(
                                onTap:
                                    () => alreadyConfirmedAddress(context, ref),
                                child: Row(
                                  children: [
                                    const Icon(Atlas.envelope_check_thin),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(lang.alreadyConfirmed),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap:
                                    () =>
                                        confirmationTokenAddress(context, ref),
                                child: Row(
                                  children: [
                                    const Icon(Atlas.passcode_thin),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(lang.confirmWithToken),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () => onUnregister(context, ref),
                                child: Row(
                                  children: [
                                    const Icon(Atlas.trash_can_thin),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        lang.remove,
                                        style: textTheme.labelSmall,
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
    final lang = L10n.of(context);
    showAdaptiveDialog(
      context: context,
      builder:
          (context) => DefaultDialog(
            title: Text(lang.areYouSureYouWantToUnregisterEmailAddress),
            actions: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.no),
              ),
              ActerPrimaryActionButton(
                onPressed: () async {
                  final account = await ref.read(accountProvider.future);
                  await account.removeEmailAddress(emailAddress);
                  ref.invalidate(emailAddressesProvider);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(lang.yes),
              ),
            ],
          ),
    );
  }

  Future<void> alreadyConfirmedAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lang = L10n.of(context);
    final newValue = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const PasswordConfirm(),
    );
    if (!context.mounted) return;
    if (newValue == null) return;
    EasyLoading.show(status: lang.tryingToConfirmToken);
    final account = await ref.read(accountProvider.future);
    try {
      await account.tryConfirmEmailStatus(emailAddress, newValue);
      ref.invalidate(emailAddressesProvider);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.looksGoodAddressConfirmed);
    } catch (e, s) {
      _log.severe('Failed to confirm token', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToConfirmToken(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> confirmationTokenAddress(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final lang = L10n.of(context);
    final newValue = await showDialog<EmailConfirm>(
      context: context,
      builder: (BuildContext context) => const TokenConfirm(),
    );
    if (!context.mounted) return;
    if (newValue == null) return;
    EasyLoading.show(status: lang.tryingToConfirmToken);
    final account = await ref.read(accountProvider.future);
    try {
      final result = await account.submitTokenFromEmail(
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
        EasyLoading.showToast(lang.looksGoodAddressConfirmed);
      } else {
        _log.severe('Invalid token or password');
        EasyLoading.showError(
          lang.invalidTokenOrPassword,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e, s) {
      _log.severe('Failed to confirm token', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToConfirmToken(e),
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
  static Key passwordConfirmTxt = const Key('password-confirm-txt');
  static Key passwordConfirmBtn = const Key('password-confirm-btn');

  const PasswordConfirm({super.key});

  @override
  State<PasswordConfirm> createState() => _PasswordConfirmState();
}

class _PasswordConfirmState extends State<PasswordConfirm> {
  final TextEditingController newPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'password confirm form',
  );
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.needYourPasswordToConfirm),
      // The token-reset path is just the process by which control over that email address is confirmed.
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                key: PasswordConfirm.passwordConfirmTxt,
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: lang.yourPassword,
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
          child: Text(lang.cancel),
        ),
        ActerPrimaryActionButton(
          key: PasswordConfirm.passwordConfirmBtn,
          onPressed: () => onSubmit(context),
          child: Text(lang.submit),
        ),
      ],
    );
  }

  void togglePassword() {
    setState(() => passwordVisible = !passwordVisible);
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'token confirm form',
  );
  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.confirmationToken),
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
                decoration: InputDecoration(hintText: lang.token),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: newPassword,
                decoration: InputDecoration(
                  hintText: lang.yourPassword,
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
          child: Text(lang.cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () => onSubmit(context),
          child: Text(lang.submit),
        ),
      ],
    );
  }

  void togglePassword() {
    setState(() => passwordVisible = !passwordVisible);
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
