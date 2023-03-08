import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/constants.dart';
import 'package:effektio/common/widgets/custom_button.dart';
import 'package:effektio/common/controllers/network_controller.dart';
import 'package:effektio/features/onboarding/controllers/auth_controller.dart';
import 'package:effektio/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';
import 'package:effektio/common/utils/constants.dart' show LoginPageKeys;

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final networkController = Get.put(NetworkController());

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    Get.delete<NetworkController>();
    super.dispose();
  }

  void _validateLogin() async {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginPageKeys.snackbarSuccess,
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          backgroundColor: AuthTheme.authSuccess,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginPageKeys.snackbarFailed,
          content: Text(AppLocalizations.of(context)!.loginFailed),
          backgroundColor: AuthTheme.authFailed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              SizedBox(
                height: 50,
                width: 50,
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                ),
              ),
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.welcomeBack,
                style: AuthTheme.authTitleStyle,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.signInContinue,
                style: AuthTheme.authBodyStyle,
              ),
              const SizedBox(height: 35),
              SignInTextField(
                key: LoginPageKeys.usernameField,
                hintText: AppLocalizations.of(context)!.username,
                controller: username,
                validatorText: AppLocalizations.of(context)!.emptyUsername,
                type: SignInOnboardingTextFieldEnum.userName,
              ),
              const SizedBox(height: 20),
              SignInTextField(
                key: LoginPageKeys.passwordField,
                hintText: AppLocalizations.of(context)!.password,
                controller: password,
                validatorText: AppLocalizations.of(context)!.emptyPassword,
                type: SignInOnboardingTextFieldEnum.password,
              ),
              Container(
                key: LoginPageKeys.forgotPassBtn,
                margin: const EdgeInsets.only(right: 20),
                width: double.infinity,
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style:
                        AuthTheme.authBodyStyle + AuthTheme.forgotPasswordColor,
                  ),
                ),
              ),
              const SizedBox(height: 100),
              authState
                  ? const CircularProgressIndicator(
                      color: AppCommonTheme.primaryColor,
                    )
                  : CustomButton(
                      key: LoginPageKeys.submitBtn,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await ref
                              .read(authControllerProvider.notifier)
                              .login(username.text, password.text, context);
                          _validateLogin();
                          // if (networkController.isDisconnected()) {
                          //   Get.snackbar(
                          //     'No internet',
                          //     'Please turn on internet to continue',
                          //     colorText: Colors.white,
                          //   );
                          // } else {

                          // }
                        }
                      },
                      title: AppLocalizations.of(context)!.login,
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noAccount,
                    style: AuthTheme.authBodyStyle,
                  ),
                  InkWell(
                    key: LoginPageKeys.signUpBtn,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: Text(
                      AppLocalizations.of(context)!.signUp,
                      style:
                          AuthTheme.authBodyStyle + AppCommonTheme.primaryColor,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
