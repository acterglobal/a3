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
          const SizedBox(height: 80),
          Image.asset(
            'assets/icon/logo_foreground.png',
            height: 100,
            width: 100,
          ),
          const SizedBox(height: 20),
          Text(
            L10n.of(context).acter,
            style: const TextStyle(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 20),
          Text(
            L10n.of(context).readyToOrganizeAndCollaboratingText,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          Text(
            L10n.of(context).loginOrCreateProfile,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: LoginPageKeys.signUpBtn,
            onPressed: () => context.pushNamed(Routes.authRegister.name),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(L10n.of(context).createProfile),
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 25),
          OutlinedButton(
            key: Keys.loginBtn,
            onPressed: () => context.pushNamed(Routes.authLogin.name),
            child: Center(
              child: Text(L10n.of(context).logIn),
            ),
          ),
        ],
      ),
    );
  }
}
