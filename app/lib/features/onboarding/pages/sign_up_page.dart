import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/custom_button.dart';
import 'package:effektio/common/controllers/network_controller.dart';
import 'package:effektio/features/onboarding/controllers/signup_controller.dart';
import 'package:effektio/features/onboarding/pages/login_page.dart';
import 'package:effektio/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
                  SignUpTextField(
                    hintText: AppLocalizations.of(context)!.name,
                    controller: controller.name,
                    validatorText: AppLocalizations.of(context)!.missingName,
                    type: SignUpOnboardingTextFieldEnum.name,
                  ),
                  SignUpTextField(
                    hintText: AppLocalizations.of(context)!.username,
                    controller: controller.name,
                    validatorText: AppLocalizations.of(context)!.emptyUsername,
                    type: SignUpOnboardingTextFieldEnum.userName,
                  ),
                  SignUpTextField(
                    hintText: AppLocalizations.of(context)!.password,
                    controller: controller.password,
                    validatorText: AppLocalizations.of(context)!.emptyPassword,
                    type: SignUpOnboardingTextFieldEnum.password,
                  ),
                  SignUpTextField(
                    hintText: AppLocalizations.of(context)!.token,
                    controller: controller.token,
                    validatorText: AppLocalizations.of(context)!.emptyToken,
                    type: SignUpOnboardingTextFieldEnum.token,
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
                  _ActionBtn(
                    controller: controller,
                    networkController: networkController,
                    formKey: formKey,
                  ),
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
                              builder: (context) => const LoginPage(),
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
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.controller,
    required this.networkController,
    required this.formKey,
  });
  final SignUpController controller;
  final NetworkController networkController;
  final GlobalKey<FormState> formKey;
  @override
  Widget build(BuildContext context) {
    if (controller.isSubmitting) {
      return const CircularProgressIndicator(
        color: AppCommonTheme.primaryColor,
      );
    }
    return CustomButton(
      onPressed: () async {
        if (formKey.currentState!.validate()) {
          if (networkController.connectionType.value == 0) {
            Get.snackbar(
              'No internet',
              'Please turn on internet to continue',
              colorText: Colors.white,
            );
          } else {
            if (await validateSignUp(context)) {
              Navigator.pushReplacementNamed(context, '/');
            }
          }
        }
      },
      title: AppLocalizations.of(context)!.signUp,
    );
  }

  Future<bool> validateSignUp(BuildContext context) async {
    bool isRegistered = await controller.signUpSubmitted();
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
}
