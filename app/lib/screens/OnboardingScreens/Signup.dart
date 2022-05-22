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
  bool signUpclicked = false;

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
                  if (formStatus is SubmissionFailed && signUpclicked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: Duration(seconds: 5),
                        backgroundColor: Colors.redAccent,
                        content: Text(
                          'Registration failed: ${formStatus.exception.toString()}',
                        ),
                      ),
                    );
                  } else if (formStatus is SubmissionSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.greenAccent,
                        content: Text('Registration successful'),
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
                        'Lets get Started',
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Create an account to explore',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      signUpOnboardingTextField(
                        'Name',
                        nameController,
                        'Please enter Your Name',
                        SignUpOnboardingTextFieldEnum.name,
                      ),
                      signUpOnboardingTextField(
                        'user Name',
                        userNameController,
                        'Please enter User Name',
                        SignUpOnboardingTextFieldEnum.userName,
                      ),
                      signUpOnboardingTextField(
                        'Password',
                        passwordController,
                        'Please enter Password',
                        SignUpOnboardingTextFieldEnum.password,
                      ),
                      signUpOnboardingTextField(
                        'Token',
                        tokenController,
                        'Please enter Token',
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
                                    'By clicking to sign up you agree to our ',
                              ),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    debugPrint('Terms of Service"');
                                  },
                                text: 'Terms and Condition',
                                style: AuthTheme.authbodyStyle +
                                    AppCommonTheme.primaryColor,
                              ),
                              TextSpan(text: ' and that you have read our '),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    debugPrint('policy"');
                                  },
                                text: 'Privacy Policy',
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
                                    signUpclicked = true;
                                    Future.delayed(Duration(seconds: 1))
                                        .then((_) {
                                      signUpclicked = false;
                                    });
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
                                  title: 'Sign up',
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
                            'Already have an account ?  ',
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
                              'Sign in ',
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
