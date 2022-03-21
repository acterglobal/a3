import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/OnboardingWidget.dart';
import 'package:effektio/Screens/HomeScreens/HomeTabBar.dart';
import 'package:effektio/Screens/OnboardingScreens/LogIn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:effektio/common/store/AppConstants.dart';

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
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(
                height: 40,
              ),
              Text(
                'Lets get Started',
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
                'Create an account to explore',
                style: GoogleFonts.montserrat(
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
                        child: TextFormField(
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
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: TextStyle(color: Colors.white),
                          validator: (val) =>
                              val!.isEmpty ? 'Please enter First Name' : null,
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
                        child: TextFormField(
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
                            hintStyle: TextStyle(color: Colors.grey),
                          ),
                          style: TextStyle(color: Colors.white),
                          validator: (val) =>
                              val!.isEmpty ? 'Please enter Last Name' : null,
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
                      : 'Please enter vaild email',
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                child: onboardingTextField(
                  'Password',
                  passwordController,
                  'Please enter Password',
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                child: onboardingTextField(
                  'Confirm Password',
                  confirmPasswordController,
                  'Please re-enter Password',
                ),
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
                    style: GoogleFonts.montserrat(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'By clicking to sign up you agree to our ',
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
              CustomOnbaordingButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeTabBar(0),
                    ),
                  );
                  if (_formKey.currentState!.validate()) {}
                },
                title: 'Sign up',
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account ?  ',
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
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Sign in ',
                      style: GoogleFonts.montserrat(
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
    );
  }
}
