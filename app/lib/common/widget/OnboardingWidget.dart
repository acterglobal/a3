// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace
// CLASS BUTTON

import 'package:effektio/blocs/login/signIn_bloc.dart';
import 'package:effektio/blocs/login/signIn_event.dart';
import 'package:effektio/blocs/login/signIn_state.dart';
import 'package:effektio/blocs/sign_up/signup_bloc.dart';
import 'package:effektio/blocs/sign_up/signup_event.dart';
import 'package:effektio/blocs/sign_up/signup_state.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ignore: must_be_immutable
class CustomOnbaordingButton extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  CustomOnbaordingButton({
    Key? key,
    required this.onPressed,
    required this.title,
  }) : super(key: key);
  final GestureTapCallback onPressed;
  String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(left: 20, right: 20),
      child: MaterialButton(
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: Colors.pink),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        color: AppColors.primaryColor,
        onPressed: onPressed,
      ),
    );
  }
}

// ON BOARDING TEXT FILED
// ignore: unused_element
Widget onboardingTextField(
  String hintText,
  TextEditingController passwordController,
  String validatorText,
) {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20),
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.textFieldColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        return TextFormField(
          obscureText: true,
          controller: passwordController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 10.0, top: 12, right: 10),
            border: InputBorder.none,

            hintText: hintText, // pass the hint text parameter here
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: TextStyle(color: Colors.white),
          validator: (val) => val!.isEmpty ? validatorText : null,
          onChanged: (value) => context
              .read<SignInBloc>()
              .add(SignInPasswordChanged(password: value)),
        );
      },
    ),
  );
}

Widget onboardingSignUpTextField(
  String hintText,
  TextEditingController passwordController,
  String validatorText,
) {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20),
    height: 60,
    decoration: BoxDecoration(
      color: AppColors.textFieldColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: BlocBuilder<SignUpBloc, SignUpState>(
      builder: (context, state) {
        return TextFormField(
          obscureText: true,
          controller: passwordController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(left: 10.0, top: 12, right: 10),
            border: InputBorder.none,

            hintText: hintText, // pass the hint text parameter here
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: TextStyle(color: Colors.white),
          validator: (val) => val!.isEmpty ? validatorText : null,
          onChanged: (value) => context
              .read<SignUpBloc>()
              .add(SignUpPasswordChanged(password: value)),
        );
      },
    ),
  );
}
