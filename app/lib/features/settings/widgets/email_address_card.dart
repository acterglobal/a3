import 'dart:core';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
                Atlas.check_shield_thin,
                color: Theme.of(context).colorScheme.success,
              )
            : Icon(
                Atlas.xmark_shield_thin,
                color: Theme.of(context).colorScheme.error,
              ),
        title: Text(emailAddress),
        trailing: PopupMenuButton(
          itemBuilder: (BuildContext ctx) => <PopupMenuEntry>[
            PopupMenuItem(
              onTap: () async => await onDelete(ctx, ref),
              child: Row(
                children: [
                  const Icon(Atlas.exit_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      AppLocalizations.of(ctx)!.logOut,
                      style: Theme.of(ctx).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () async => await onConfirm(ctx, ref),
              child: Row(
                children: [
                  const Icon(Atlas.shield_exclamation_thin),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      AppLocalizations.of(ctx)!.verifySession,
                      style: Theme.of(ctx).textTheme.labelSmall,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> onDelete(BuildContext context, WidgetRef ref) async {
    TextEditingController passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Authentication required'),
          content: Wrap(
            children: [
              const Text(
                'Please provide your user password to confirm you want to end that session.',
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                if (ctx.mounted) {
                  Navigator.of(context).pop(false);
                }
              },
            ),
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                if (passwordController.text.isEmpty) {
                  return;
                }
                if (ctx.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        );
      },
    );
    if (result != true) {
      return;
    }
    final account = await ref.read(accountProvider.future);
    final manager = account.passwordResetManager();
    await manager.removeEmailAddress(emailAddress);
  }

  Future<void> onConfirm(BuildContext context, WidgetRef ref) async {
    final TextEditingController tokenController = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Enter the token that got from email'),
        content: TextField(controller: tokenController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, tokenController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (token != null && context.mounted) {
      final account = await ref.read(accountProvider.future);
      final manager = account.passwordResetManager();
      await manager.submitTokenFromEmail(emailAddress, token);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(
        context,
        'Confirmed this email address for password reset',
      );
    }
  }
}
