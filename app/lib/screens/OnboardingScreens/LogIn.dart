// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace

import 'package:effektio/blocs/login/form_submission_status.dart';
import 'package:effektio/blocs/login/signIn_bloc.dart';
import 'package:effektio/blocs/login/signIn_event.dart';
import 'package:effektio/blocs/login/signIn_state.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: AppColors.darkBackgroundColor,
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
                        'Sign in to Continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(left: 20, right: 20, top: 100),
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.textFieldColor,
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
                        'Password',
                        passwordController,
                        'Please enter Password',
                      ),
                      Container(
                        margin: EdgeInsets.only(right: 20),
                        width: double.infinity,
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xff008080),
                              fontWeight: FontWeight.w300,
                            ),
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
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            child: Text(
                              'Sign up ',
                              style: GoogleFonts.lato(
                                fontSize: 18,
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
