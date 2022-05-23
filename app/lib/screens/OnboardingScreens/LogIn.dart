// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:effektio/blocs/login/form_submission_status.dart';
import 'package:effektio/blocs/login/signIn_bloc.dart';
import 'package:effektio/blocs/login/signIn_event.dart';
import 'package:effektio/blocs/login/signIn_state.dart';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:flutter/material.dart';
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
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  bool signInclicked = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    userNameController.dispose();
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
                  if (formStatus is SubmissionFailed && signInclicked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          'Login failed: ${formStatus.exception.toString()}',
                        ),
                      ),
                    );
                  } else if (formStatus is SubmissionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.greenAccent,
                        content: Text('Login successful'),
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
                        'Welcome Back',
                        style: AuthTheme.authTitleStyle,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Sign in to Continue',
                        style: AuthTheme.authbodyStyle,
                      ),
                      SizedBox(
                        height: 35,
                      ),
                      signInOnboardingTextField(
                        'Username',
                        userNameController,
                        'Please enter Username',
                        SignInOnboardingTextFieldEnum.userName,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      signInOnboardingTextField(
                        'Password',
                        passwordController,
                        'Please enter Password',
                        SignInOnboardingTextFieldEnum.password,
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        width: double.infinity,
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
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
                                    signInclicked = true;
                                    Future.delayed(Duration(seconds: 1))
                                        .then((_) {
                                      signInclicked = false;
                                    });
                                    if (_formKey.currentState!.validate()) {
                                      context.read<SignInBloc>().add(
                                            SignInSubmitted(
                                              username: userNameController.text,
                                              password: passwordController.text,
                                            ),
                                          );
                                    }
                                  },
                                  title: 'Login',
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
                            "Don't have an account ?  ",
                            style: AuthTheme.authbodyStyle,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              'Sign up ',
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
