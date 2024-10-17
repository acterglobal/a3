import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::dialogs::deactivate');

const deactivateConfirmBtn = Key('deactivate-account-confirm');
const deactivateCancelBtn = Key('deactivate-account-cancel');
const deactivatePasswordField = Key('deactivate-password-field');

// Can be extended to be reusable dialog as riverpod states get added.
// Ref can be used to read any provider which are declared.
void deactivationConfirmationDialog(BuildContext context, WidgetRef ref) {
  TextEditingController passwordController = TextEditingController();
  final theme = Theme.of(context).colorScheme;
  final lang = L10n.of(context);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          lang.deactivateAccount,
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
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        Text(
                          lang.deactivateAccountTitle,
                          style: TextStyle(
                            color: theme.error,
                            fontSize: 20,
                          ),
                        ),
                        Text(lang.deactivateAccountDescription),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  lang.deactivateAccountPasswordTitle,
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
                  decoration: InputDecoration(hintText: lang.password),
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          OutlinedButton(
            key: deactivateCancelBtn,
            onPressed: () => Navigator.pop(context),
            child: Text(lang.cancel),
          ),
          ActerDangerActionButton(
            key: deactivateConfirmBtn,
            onPressed: () async => _onConfirm(
              context,
              ref,
              passwordController.text,
            ),
            child: Text(lang.deactivate),
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
  final lang = L10n.of(context);
  EasyLoading.show(status: lang.deactivatingYourAccount);
  final sdk = await ref.read(sdkProvider.future);
  try {
    final result = await sdk.deactivateAndDestroyCurrentClient(password);
    if (!result) {
      _log.severe('Failed to deactivate and remove this client');
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.deactivationAndRemovingFailed,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    EasyLoading.dismiss();
    if (!context.mounted) return;
    context.goNamed(Routes.main.name);
  } catch (e, s) {
    _log.severe('Failed to deactivate and remove this client', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.deactivatingFailed(e),
      duration: const Duration(seconds: 3),
    );
  }
}
