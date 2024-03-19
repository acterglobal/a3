import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class IntroProfile extends StatelessWidget {
  const IntroProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: introGradient,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 100),
          _buildLogo(),
          const SizedBox(height: 20),
          _buildHeadlineText(context),
          const SizedBox(height: 10),
          _buildPreviewLabel(context),
          const SizedBox(height: 20),
          _buildDescription(context),
          const SizedBox(height: 50),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/icon/logo_foreground.png',
      height: 200,
      width: 200,
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Column(
      children: [
        Text(
          L10n.of(context).makeADifference,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          L10n.of(context).joinActer,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: greenColor),
        ),
      ],
    );
  }

  Widget _buildPreviewLabel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text(
        L10n.of(context).preview,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      L10n.of(context).takeAFirstStep,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          key: LoginPageKeys.signUpBtn,
          onPressed: () => context.pushNamed(Routes.authRegister.name),
          child: Text(
            L10n.of(context).signUp,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          L10n.of(context).or,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          key: Keys.loginBtn,
          onPressed: () => context.pushNamed(Routes.authLogin.name),
          child: Text(
            L10n.of(context).logIn,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
