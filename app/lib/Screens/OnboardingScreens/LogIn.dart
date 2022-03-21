// ignore_for_file: prefer_const_constructors

import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/repository/client.dart';
import 'package:effektio/screens/OnboardingScreens/Signup.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio/common/store/AppConstants.dart';

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

  // Future<Client> login(String username, String password) async {
  //   final sdk = await EffektioSdk.instance;
  //   Client client = await sdk.login(username, password);
  //   return client;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
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
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(
                height: 40,
              ),
              Text(
                'Welcome Back',
                style: GoogleFonts.montserrat(
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
                style: GoogleFonts.montserrat(
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
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    contentPadding:
                        EdgeInsets.only(left: 10.0, top: 12, right: 10),

                    border: InputBorder.none,
                    hintText:
                        'Email Address', // pass the hint text parameter here
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.white),
                  validator: (value) => ValidConstants.isEmail(value!)
                      ? null
                      : 'Please enter valid email',
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
                    style: GoogleFonts.montserrat(
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
              CustomOnbaordingButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    login(emailController.text, passwordController.text)
                        .then((a) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.greenAccent,
                          content: Text('Login successful'),
                        ),
                      );
                      Navigator.pop(context);
                    }).catchError((e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text('Login failed: $e'),
                        ),
                      );
                    });
                  }
                },
                title: 'Login',
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account ?  ",
                    style: GoogleFonts.montserrat(
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
                          builder: (context) => SignupScreen(),
                        ),
                      );
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
    );
  }
}
