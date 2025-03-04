import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/auth/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class IntroProfile extends StatelessWidget {
  const IntroProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: true, body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    // limit the to always show the button even if the keyboard is opened
    final imageSize = MediaQuery.of(context).size.height / 6;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                const Spacer(),
                LogoWidget(height: imageSize, width: imageSize),
                const SizedBox(height: 30),
                _buildHeadlineText(context),
                const SizedBox(height: 10),
                _buildPreviewLabel(context),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Spacer(),
                _buildDescription(context),
                const Spacer(),
                _buildActionButtons(context),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          lang.makeADifference,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          lang.joinActer,
          style: textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.textHighlight,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewLabel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.textColor),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        L10n.of(context).preview,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Text(
          L10n.of(context).takeAFirstStep,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActerPrimaryActionButton(
              key: LoginPageKeys.signUpBtn,
              onPressed: () => context.pushNamed(Routes.authRegister.name),
              child: Text(lang.signUp, style: textTheme.bodyMedium),
            ),
            const SizedBox(height: 16),
            Text(
              lang.or,
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              key: Keys.loginBtn,
              onPressed: () => context.pushNamed(Routes.authLogin.name),
              child: Text(lang.logIn, style: textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
