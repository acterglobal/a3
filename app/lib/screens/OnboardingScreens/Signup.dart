// ignore_for_file: prefer_const_constructors

import 'package:effektio/blocs/sign_up/form_submition_status.dart';
import 'package:effektio/blocs/sign_up/signup_bloc.dart';
import 'package:effektio/blocs/sign_up/signup_event.dart';
import 'package:effektio/blocs/sign_up/signup_state.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
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
                      Container(
                        margin: EdgeInsets.only(left: 20, right: 20, top: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.textFieldColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: BlocBuilder<SignUpBloc, SignUpState>(
                                  builder: (context, state) {
                                    return TextFormField(
                                      controller: firstNameController,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                          left: 10.0,
                                          top: 12,
                                          right: 10,
                                        ),
                                        border: InputBorder.none,
                                        hintText:
                                            'First Name', // pass the hint text parameter here
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      validator: (val) => val!.isEmpty
                                          ? 'Please enter First Name'
                                          : null,
                                      onChanged: (value) =>
                                          context.read<SignUpBloc>().add(
                                                SignUpFirstNameChanged(
                                                  firstName: value,
                                                ),
                                              ),
                                    );
                                  },
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
                                  color: AppColors.textFieldColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: BlocBuilder<SignUpBloc, SignUpState>(
                                  builder: (context, state) {
                                    return TextFormField(
                                      controller: lastNameController,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(
                                          left: 10.0,
                                          top: 12,
                                          right: 10,
                                        ),
                                        border: InputBorder.none,
                                        hintText:
                                            'Last name', // pass the hint text parameter here
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      validator: (val) => val!.isEmpty
                                          ? 'Please enter Last Name'
                                          : null,
                                      onChanged: (value) =>
                                          context.read<SignUpBloc>().add(
                                                SignUpLastNameChanged(
                                                  lastName: value,
                                                ),
                                              ),
                                    );
                                  },
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
                          color: AppColors.textFieldColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: BlocBuilder<SignUpBloc, SignUpState>(
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
                                hintText:
                                    'Email Address', // pass the hint text parameter here
                                hintStyle: TextStyle(color: Colors.grey),
                              ),
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!value[0].startsWith('@')) {
                                  return 'Please enter correct username format (starts with @)';
                                }
                                return null;
                              },
                              onChanged: (value) => context
                                  .read<SignUpBloc>()
                                  .add(SignUpUsernameChanged(username: value)),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      onboardingSignUpTextField(
                        'Password',
                        passwordController,
                        'Please enter Password',
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
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
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
                                style: TextStyle(color: Colors.redAccent),
                              ),
                              TextSpan(text: ' and that you have read our '),
                              TextSpan(
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    debugPrint('policy"');
                                  },
                                text: 'Privacy Policy',
                                style: TextStyle(color: AppColors.primaryColor),
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
                                              username: emailController.text,
                                              password: passwordController.text,
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
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
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w300,
                              ),
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
