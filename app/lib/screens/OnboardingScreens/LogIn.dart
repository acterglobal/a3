// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:effektio/blocs/login/form_submission_status.dart';
import 'package:effektio/blocs/login/signIn_bloc.dart';
import 'package:effektio/blocs/login/signIn_event.dart';
import 'package:effektio/blocs/login/signIn_state.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:themed/themed.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            BlocProvider(
              create: (context) => SignInBloc(),
              child: BlocListener<SignInBloc, SignInState>(
                listener: (context, state) {
                  final formStatus = state.formStatus;
                  if (formStatus is SubmissionFailed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          '${AppLocalizations.of(context)!.loginFailed}: ${formStatus.exception.toString()}',
                        ),
                      ),
                    );
                  } else if (formStatus is SubmissionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.greenAccent,
                        content:
                            Text(AppLocalizations.of(context)!.loginSuccess),
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
                      Container(
                        margin: EdgeInsets.only(left: 20, right: 20, top: 100),
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppCommonTheme.textFieldColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: BlocBuilder<SignInBloc, SignInState>(
                          builder: (context, state) {
                            return TextFormField(
                              controller: emailController,
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(
                                  left: 10.0,
                                  top: 12,
                                  right: 10,
                                ),

                                border: InputBorder.none,
                                hintText: AppLocalizations.of(context)!
                                    .email, // pass the hint text parameter here
                                hintStyle:
                                    TextStyle(color: AuthTheme.hintTextColor),
                              ),
                              style: TextStyle(
                                color: AuthTheme.textFieldTextColor,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyEmail;
                                }
                                if (!value[0].startsWith('@')) {
                                  return AppLocalizations.of(context)!
                                      .missingPrefix;
                                }
                                return null;
                              },
                              onChanged: (value) => context
                                  .read<SignInBloc>()
                                  .add(SignInUsernameChanged(username: value)),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      onboardingTextField(
                        AppLocalizations.of(context)!.password,
                        passwordController,
                        AppLocalizations.of(context)!.emptyPassword,
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
                      BlocBuilder<SignInBloc, SignInState>(
                        builder: ((context, state) {
                          return state.formStatus is FormSubmitting
                              ? CircularProgressIndicator()
                              : CustomOnbaordingButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<SignInBloc>().add(
                                            SignInSubmitted(
                                              username: emailController.text,
                                              password: passwordController.text,
                                            ),
                                          );
                                    }
                                  },
                                  title: AppLocalizations.of(context)!.login,
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
                            AppLocalizations.of(context)!.noAccount,
                            style: AuthTheme.authbodyStyle,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
