// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace
// CLASS BUTTON

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        color: AppCommonTheme.primaryColor,
        onPressed: onPressed,
      ),
    );
  }
}

enum SignUpOnboardingTextFieldEnum { name, userName, password, token }

// ON BOARDING TEXT FILED
// ignore: unused_element
Widget signUpOnboardingTextField(
  String hintText,
  TextEditingController controller,
  String validatorText,
  SignUpOnboardingTextFieldEnum type,
) {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
    height: 60,
    decoration: BoxDecoration(
      color: AppCommonTheme.textFieldColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: TextFormField(
      inputFormatters: (type == SignUpOnboardingTextFieldEnum.userName) ||
              (type == SignUpOnboardingTextFieldEnum.password)
          ? [
              FilteringTextInputFormatter.deny(RegExp(r'\s')),
            ]
          : [],
      obscureText: type == SignUpOnboardingTextFieldEnum.password,
      controller: controller,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(left: 10.0, top: 12, right: 10),
        border: InputBorder.none,

        hintText: hintText, // pass the hint text parameter here
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: TextStyle(color: Colors.white),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return validatorText;
        }
        return null;
      },
      onChanged: (value) {
        switch (type) {
          case SignUpOnboardingTextFieldEnum.name:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
          case SignUpOnboardingTextFieldEnum.userName:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
          case SignUpOnboardingTextFieldEnum.password:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
          case SignUpOnboardingTextFieldEnum.token:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
        }
      },
    ),
  );
}

enum SignInOnboardingTextFieldEnum { userName, password }

Widget signInOnboardingTextField(
  String hintText,
  TextEditingController controller,
  String validatorText,
  SignInOnboardingTextFieldEnum type,
) {
  return Container(
    margin: EdgeInsets.only(left: 20, right: 20),
    height: 60,
    decoration: BoxDecoration(
      color: AppCommonTheme.textFieldColor,
      borderRadius: BorderRadius.circular(4),
    ),
    child: TextFormField(
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      obscureText: type == SignInOnboardingTextFieldEnum.password,
      controller: controller,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(left: 10.0, top: 12, right: 10),
        border: InputBorder.none,

        hintText: hintText, // pass the hint text parameter here
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: TextStyle(color: Colors.white),
      validator: (val) {
        if (val == null || val.trim().isEmpty) {
          return validatorText;
        }

        return null;
      },
      onChanged: (value) {
        switch (type) {
          case SignInOnboardingTextFieldEnum.userName:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
          case SignInOnboardingTextFieldEnum.password:
            controller.text = value;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
            break;
        }
      },
    ),
  );
}
