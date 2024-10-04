import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class LoggedOutScreen extends ConsumerWidget {
  final bool softLogout;
  const LoggedOutScreen({
    super.key,
    required this.softLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    text: L10n.of(context).access,
                    style: Theme.of(context).textTheme.headlineLarge,
                    children: <TextSpan>[
                      TextSpan(
                        text: ' ${L10n.of(context).denied}',
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
                child: Text(
                  L10n.of(context).yourSessionHasBeenTerminatedByServer,
                ),
              ),
              softLogout
                  ? OutlinedButton(
                      onPressed: () => context.goNamed(Routes.intro.name),
                      child: Text(L10n.of(context).loginAgain),
                    )
                  : OutlinedButton(
                      onPressed: () => logoutConfirmationDialog(context, ref),
                      child: Text(L10n.of(context).clearDBAndReLogin),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
