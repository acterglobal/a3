import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';

import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const deactivateConfirmBtn = Key('deactivate-account-confirm');
const deactivateCancelBtn = Key('deactivate-account-cancel');
const deactivatePasswordField = Key('deactivate-password-field');

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void deactivationConfirmationDialog(BuildContext context, WidgetRef ref) {
  TextEditingController passwordController = TextEditingController();
  final theme = Theme.of(context).colorScheme;
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(
          L10n.of(context).deactivateAccount,
          style: TextStyle(
            color: theme.error,
            fontSize: 26,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    color: Theme.of(context).colorScheme.background,
                    child: Column(
                      children: [
                        Text(
                          L10n.of(context).deactivateAccountTitle,
                          style: TextStyle(
                            color: theme.error,
                            fontSize: 20,
                          ),
                        ),
                        Text(L10n.of(context).deactivateAccountDescription),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  L10n.of(context).deactivateAccountPasswordTitle,
                  style: TextStyle(
                    color: theme.error,
                    fontSize: 20,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: TextField(
                  key: deactivatePasswordField,
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: L10n.of(context).password,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          OutlinedButton(
            key: deactivateCancelBtn,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).cancel),
          ),
          ActerDangerActionButton(
            key: deactivateConfirmBtn,
            onPressed: () async => _onConfirm(
              context,
              ref,
              passwordController.text,
            ),
            child: Text(L10n.of(context).deactivate),
          ),
        ],
      );
    },
  );
}

Future<void> _onConfirm(
  BuildContext context,
  WidgetRef ref,
  String password,
) async {
  EasyLoading.show(status: L10n.of(context).deactivatingYourAccount);
  final sdk = await ref.read(sdkProvider.future);
  try {
    final result = await sdk.deactivateAndDestroyCurrentClient(password);
    if (!result) {
      if (context.mounted) {
        EasyLoading.showError(
          L10n.of(context).deactivationAndRemovingFailed,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }
    EasyLoading.dismiss();
    if (!context.mounted) return;
    context.goNamed(Routes.main.name);
  } catch (err) {
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      L10n.of(context).deactivatingFailed(err),
      duration: const Duration(seconds: 3),
    );
  }
}
