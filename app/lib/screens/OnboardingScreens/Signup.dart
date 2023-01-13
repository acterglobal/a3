import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/network_controller.dart';
import 'package:effektio/controllers/signup_controller.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/widgets/OnboardingWidget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreentate createState() => _SignupScreentate();
}

class _SignupScreentate extends State<SignupScreen> {
  final formKey = GlobalKey<FormState>();
  final SignUpController signUpController = Get.put(SignUpController());
  final networkController = Get.put(NetworkController());

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    Get.delete<SignUpController>();
    Get.delete<NetworkController>();
    super.dispose();
  }

  Future<bool> validateSignUp() async {
    bool isRegistered = await signUpController.signUpSubmitted();
    if (isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          backgroundColor: AuthTheme.authSuccess,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginFailed),
          backgroundColor: AuthTheme.authFailed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    return isRegistered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: GetBuilder<SignUpController>(
          builder: (SignUpController controller) {
            return Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: SvgPicture.asset('assets/images/logo.svg'),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    AppLocalizations.of(context)!.onboardText,
                    style: AuthTheme.authTitleStyle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.createAccountText,
                    style: AuthTheme.authBodyStyle,
                  ),
                  const SizedBox(height: 20),
                  signUpOnboardingTextField(
                    AppLocalizations.of(context)!.name,
                    controller.name,
                    AppLocalizations.of(context)!.missingName,
                    SignUpOnboardingTextFieldEnum.name,
                  ),
                  signUpOnboardingTextField(
                    AppLocalizations.of(context)!.username,
                    controller.username,
                    AppLocalizations.of(context)!.emptyUsername,
                    SignUpOnboardingTextFieldEnum.userName,
                  ),
                  signUpOnboardingTextField(
                    AppLocalizations.of(context)!.password,
                    controller.password,
                    AppLocalizations.of(context)!.emptyPassword,
                    SignUpOnboardingTextFieldEnum.password,
                  ),
                  signUpOnboardingTextField(
                    AppLocalizations.of(context)!.token,
                    controller.token,
                    AppLocalizations.of(context)!.emptyToken,
                    SignUpOnboardingTextFieldEnum.token,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        // Note: Styles for TextSpans must be explicitly defined.
                        // Child text spans will inherit styles from parent
                        style: AuthTheme.authBodyStyle,
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                '${AppLocalizations.of(context)!.termsText1} ',
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                debugPrint('Terms of Service"');
                              },
                            text: AppLocalizations.of(context)!.termsText2,
                            style: AuthTheme.authBodyStyle +
                                AppCommonTheme.primaryColor,
                          ),
                          TextSpan(
                            text:
                                ' ${AppLocalizations.of(context)!.termsText3} ',
                          ),
                          TextSpan(
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                debugPrint('policy"');
                              },
                            text: AppLocalizations.of(context)!.termsText4,
                            style: AuthTheme.authBodyStyle +
                                AppCommonTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  buildActionButton(controller),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.haveAccount}  ',
                        style: AuthTheme.authBodyStyle,
                      ),
                      InkWell(
                        onTap: () {
                          Get.delete<SignUpController>();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.login,
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

  Widget buildActionButton(SignUpController controller) {
    if (controller.isSubmitting) {
      return const CircularProgressIndicator(
        color: AppCommonTheme.primaryColor,
      );
    }
    return CustomOnbaordingButton(
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          if (networkController.connectionType.value == 0) {
            Get.snackbar(
              'No internet',
              'Please turn on internet to continue',
              colorText: Colors.white,
            );
          } else {
            if (await validateSignUp()) {
              Navigator.pushReplacementNamed(context, '/');
            }
          }
        }
      },
      title: AppLocalizations.of(context)!.signUp,
    );
  }
}
