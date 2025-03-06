import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class LoggedOutScreen extends ConsumerWidget {
  final bool softLogout;

  const LoggedOutScreen({super.key, required this.softLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: kToolbarHeight),
        child: Center(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                height: 100,
                width: 100,
                child: SvgPicture.asset(
                  'assets/images/undraw_access_denied_re_awnf.svg',
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: lang.access,
                    style: Theme.of(context).textTheme.headlineLarge,
                    children: <TextSpan>[
                      TextSpan(
                        text: ' ${lang.denied}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                child: Text(lang.yourSessionHasBeenTerminatedByServer),
              ),
              softLogout
                  ? OutlinedButton(
                    onPressed: () => context.goNamed(Routes.intro.name),
                    child: Text(lang.loginAgain),
                  )
                  : OutlinedButton(
                    onPressed: () => logoutConfirmationDialog(context, ref),
                    child: Text(lang.clearDBAndReLogin),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
