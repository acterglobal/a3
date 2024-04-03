import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:flutter/material.dart';
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
  showDialog(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: Text(
          L10n.of(context).deactivate('withAccount'),
          style: TextStyle(
            color: AppTheme.brandColorScheme.error,
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
                            color: AppTheme.brandColorScheme.error,
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
                    color: AppTheme.brandColorScheme.error,
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
          TextButton(
            key: deactivateCancelBtn,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).cancel),
          ),
          TextButton(
            key: deactivateConfirmBtn,
            onPressed: () async => _onConfirm(
              context,
              ref,
              passwordController.text,
            ),
            child: Text(L10n.of(context).deactivate('')),
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
  showAdaptiveDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => DefaultDialog(
      title: Text(
        L10n.of(context).deactivatingYourAccount,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    ),
  );
  final sdk = await ref.read(sdkProvider.future);
  try {
    if (!await sdk.deactivateAndDestroyCurrentClient(password)) {
      if (!context.mounted) return;
      throw L10n.of(context).deactivationAndRemovingFailed;
    }
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    // remove pop up
    Navigator.of(context, rootNavigator: true).pop();
    // remove ourselves
    Navigator.of(context, rootNavigator: true).pop();
    context.goNamed(Routes.main.name);
  } catch (err) {
    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }

    showAdaptiveDialog(
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(
          '${L10n.of(context).deactivatingFailed}: \n $err"',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).close),
          ),
        ],
      ),
    );
  }
}
