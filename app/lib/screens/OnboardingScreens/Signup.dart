// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:effektio/common/store/AppConstants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:themed/themed.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreentate createState() => _SignupScreentate();
}

class _SignupScreentate extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    passwordController.dispose();
    lastNameController.dispose();
    firstNameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 80,
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
                AppLocalizations.of(context)!.onboardText,
                style: AuthTheme.authTitleStyle,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                AppLocalizations.of(context)!.createAccountText,
                style: AuthTheme.authbodyStyle,
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20, top: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppCommonTheme.textFieldColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: firstNameController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              left: 10.0,
                              top: 12,
                              right: 10,
                            ),
                            border: InputBorder.none,
                            hintText: AppLocalizations.of(context)!
                                .firstName, // pass the hint text parameter here
                            hintStyle:
                                TextStyle(color: AuthTheme.hintTextColor),
                          ),
                          style: TextStyle(color: AuthTheme.textFieldTextColor),
                          validator: (val) => val!.isEmpty
                              ? AppLocalizations.of(context)!.missingFirstName
                              : null,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppCommonTheme.textFieldColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextFormField(
                          controller: lastNameController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              left: 10.0,
                              top: 12,
                              right: 10,
                            ),
                            border: InputBorder.none,
                            hintText: AppLocalizations.of(context)!
                                .lastName, // pass the hint text parameter here
                            hintStyle:
                                TextStyle(color: AuthTheme.hintTextColor),
                          ),
                          style: TextStyle(color: AuthTheme.textFieldTextColor),
                          validator: (val) => val!.isEmpty
                              ? AppLocalizations.of(context)!.missingLastName
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                height: 60,
                decoration: BoxDecoration(
                  color: AppCommonTheme.textFieldColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.only(left: 10.0, top: 12, right: 10),
                    border: InputBorder.none,
                    hintText: AppLocalizations.of(context)!
                        .email, // pass the hint text parameter here
                    hintStyle: TextStyle(color: AuthTheme.hintTextColor),
                  ),
                  style: TextStyle(color: AuthTheme.textFieldTextColor),
                  validator: (value) => ValidConstants.isEmail(value!)
                      ? null
                      : AppLocalizations.of(context)!.validEmail,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 40,
              ),
              Container(
                margin: EdgeInsets.only(left: 20, right: 20),
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: AuthTheme.authbodyStyle,
                    children: <TextSpan>[
                      TextSpan(
                        text: '${AppLocalizations.of(context)!.termsText1} ',
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            debugPrint('Terms of Service"');
                          },
                        text: AppLocalizations.of(context)!.termsText2,
                        style: AuthTheme.authbodyStyle +
                            AppCommonTheme.primaryColor,
                      ),
                      TextSpan(
                          text:
                              ' ${AppLocalizations.of(context)!.termsText3} '),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            debugPrint('policy"');
                          },
                        text: AppLocalizations.of(context)!.termsText4,
                        style: AuthTheme.authbodyStyle +
                            AppCommonTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              ),
              CustomOnbaordingButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {}
                },
                title: AppLocalizations.of(context)!.signUp,
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.haveAccount}  ',
                    style: AuthTheme.authbodyStyle,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.login,
                      style:
                          AuthTheme.authbodyStyle + AppCommonTheme.primaryColor,
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
