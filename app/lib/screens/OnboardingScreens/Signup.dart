// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/blocs/sign_up/form_submition_status.dart';
import 'package:effektio/blocs/sign_up/signup_bloc.dart';
import 'package:effektio/blocs/sign_up/signup_event.dart';
import 'package:effektio/blocs/sign_up/signup_state.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:themed/themed.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreentate createState() => _SignupScreentate();
}

class _SignupScreentate extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final tokenController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    userNameController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BlocProvider(
              create: (context) => SignUpBloc(),
              child: BlocListener<SignUpBloc, SignUpState>(
                listener: (context, state) {
                  final formStatus = state.formStatus;
                  if (formStatus is SubmissionFailed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: Duration(seconds: 5),
                        backgroundColor: AuthTheme.authFailed,
                        content: Text(
                          '${AppLocalizations.of(context)!.registerFailed}, ${formStatus.exception.toString()}',
                        ),
                      ),
                    );
                  } else if (formStatus is SubmissionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AuthTheme.authSuccess,
                        content:
                            Text(AppLocalizations.of(context)!.registerSuccess),
                      ),
                    );
                    Navigator.pushNamed(context, '/');
                  }
                },
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
                      SizedBox(
                        height: 20,
                      ),
                      signUpOnboardingTextField(
                        AppLocalizations.of(context)!.name,
                        nameController,
                        AppLocalizations.of(context)!.missingName,
                        SignUpOnboardingTextFieldEnum.name,
                      ),
                      signUpOnboardingTextField(
                        AppLocalizations.of(context)!.username,
                        userNameController,
                        AppLocalizations.of(context)!.emptyUsername,
                        SignUpOnboardingTextFieldEnum.userName,
                      ),
                      signUpOnboardingTextField(
                        AppLocalizations.of(context)!.password,
                        passwordController,
                        AppLocalizations.of(context)!.emptyPassword,
                        SignUpOnboardingTextFieldEnum.password,
                      ),
                      signUpOnboardingTextField(
                        AppLocalizations.of(context)!.token,
                        tokenController,
                        AppLocalizations.of(context)!.emptyToken,
                        SignUpOnboardingTextFieldEnum.token,
                      ),
                      SizedBox(
                        height: 30,
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
                                text:
                                    '${AppLocalizations.of(context)!.termsText1} ',
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
                                    ' ${AppLocalizations.of(context)!.termsText3} ',
                              ),
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
                      BlocBuilder<SignUpBloc, SignUpState>(
                        builder: ((context, state) {
                          return state.formStatus is FormSubmitting
                              ? CircularProgressIndicator()
                              : CustomOnbaordingButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<SignUpBloc>().add(
                                            SignUpSubmitted(
                                              username: userNameController.text
                                                  .trim(),
                                              password: passwordController.text
                                                  .trim(),
                                              name: nameController.text.trim(),
                                              token:
                                                  tokenController.text.trim(),
                                            ),
                                          );
                                    }
                                  },
                                  title: AppLocalizations.of(context)!.signUp,
                                );
                        }),
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
                              style: AuthTheme.authbodyStyle +
                                  AppCommonTheme.primaryColor,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
