import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/custom_button.dart';
import 'package:effektio/features/onboarding/controllers/login_controller.dart';
import 'package:effektio/common/controllers/network_controller.dart';
import 'package:effektio/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';
import 'package:effektio/common/utils/constants.dart'
    show LoginScreenKeys, Keys;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final loginController = Get.put(LoginController());
  final networkController = Get.put(NetworkController());

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    Get.delete<LoginController>();
    Get.delete<NetworkController>();
    super.dispose();
  }

  Future<bool> validateLogin() async {
    bool isLoggedIn = await loginController.loginSubmitted();
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginScreenKeys.snackbarSuccess,
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          backgroundColor: AuthTheme.authSuccess,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginScreenKeys.snackbarFailed,
          content: Text(AppLocalizations.of(context)!.loginFailed),
          backgroundColor: AuthTheme.authFailed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: GetBuilder<LoginController>(
          builder: (LoginController controller) {
            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: SvgPicture.asset('assets/images/logo.svg'),
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
                    key: LoginScreenKeys.usernameField,
                    hintText: AppLocalizations.of(context)!.username,
                    controller: controller.username,
                    validatorText: AppLocalizations.of(context)!.emptyUsername,
                    type: SignInOnboardingTextFieldEnum.userName,
                  ),
                  const SizedBox(height: 20),
                  SignInTextField(
                    key: LoginScreenKeys.passwordField,
                    hintText: AppLocalizations.of(context)!.password,
                    controller: controller.password,
                    validatorText: AppLocalizations.of(context)!.emptyPassword,
                    type: SignInOnboardingTextFieldEnum.password,
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    width: double.infinity,
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        AppLocalizations.of(context)!.forgotPassword,
                        style: AuthTheme.authBodyStyle +
                            AuthTheme.forgotPasswordColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  controller.isSubmitting
                      ? const CircularProgressIndicator(
                          color: AppCommonTheme.primaryColor,
                        )
                      : CustomButton(
                          key: LoginScreenKeys.submitBtn,
                          onPressed: () async {
                            controller.isSubmitting = true;
                            if (formKey.currentState!.validate()) {
                              if (networkController.connectionType.value == 0) {
                                Get.snackbar(
                                  'No internet',
                                  'Please turn on internet to continue',
                                  colorText: Colors.white,
                                );
                              } else {
                                if (await validateLogin()) {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              }
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
                        onTap: () {
                          Get.delete<LoginController>();
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: Text(
                          AppLocalizations.of(context)!.signUp,
                          style: AuthTheme.authBodyStyle +
                              AppCommonTheme.primaryColor,
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
