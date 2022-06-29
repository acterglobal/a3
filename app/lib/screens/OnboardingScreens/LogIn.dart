// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:themed/themed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final loginController = Get.put(LoginController());
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    Get.delete<LoginController>();
    super.dispose();
  }

  Future<bool> _loginValidate() async {
    bool isLoggedIn = false;
    await loginController.loginSubmitted().then(
          (value) => {
            if (value)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.loginSuccess),
                    backgroundColor: AuthTheme.authSuccess,
                    duration: const Duration(seconds: 4),
                  ),
                ),
                isLoggedIn = true,
              }
            else
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.loginFailed),
                    backgroundColor: AuthTheme.authFailed,
                    duration: const Duration(seconds: 4),
                  ),
                ),
                isLoggedIn = false,
              }
          },
        );
    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            GetBuilder<LoginController>(
              builder: (LoginController controller) {
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                      ),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: SvgPicture.asset('assets/images/logo.svg'),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      Text(
                        AppLocalizations.of(context)!.welcomeBack,
                        style: AuthTheme.authTitleStyle,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        AppLocalizations.of(context)!.signInContinue,
                        style: AuthTheme.authbodyStyle,
                      ),
                      SizedBox(
                        height: 35,
                      ),
                      signInOnboardingTextField(
                        AppLocalizations.of(context)!.username,
                        controller.username,
                        AppLocalizations.of(context)!.emptyUsername,
                        SignInOnboardingTextFieldEnum.userName,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      signInOnboardingTextField(
                        AppLocalizations.of(context)!.password,
                        controller.password,
                        AppLocalizations.of(context)!.emptyPassword,
                        SignInOnboardingTextFieldEnum.password,
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        width: double.infinity,
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            AppLocalizations.of(context)!.forgotPassword,
                            style: AuthTheme.authbodyStyle +
                                AuthTheme.forgotPasswordColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 100,
                      ),
                      controller.isSubmitting
                          ? CircularProgressIndicator(
                              color: AppCommonTheme.primaryColor,
                            )
                          : CustomOnbaordingButton(
                              onPressed: () async {
                                controller.isSubmitting = true;
                                if (_formKey.currentState!.validate()) {
                                  await _loginValidate().then(
                                    (value) => {
                                      if (value)
                                        {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/',
                                          ),
                                        }
                                    },
                                  );
                                }
                              },
                              title: AppLocalizations.of(context)!.login,
                            ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.noAccount,
                            style: AuthTheme.authbodyStyle,
                          ),
                          InkWell(
                            onTap: () {
                              Get.delete<LoginController>();
                              Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                              );
                            },
                            child: Text(
                              AppLocalizations.of(context)!.signUp,
                              style: AuthTheme.authbodyStyle +
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
          ],
        ),
      ),
    );
  }
}
