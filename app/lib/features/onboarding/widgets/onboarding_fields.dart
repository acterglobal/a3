import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SignUpOnboardingTextFieldEnum { name, userName, password, token }

// ON BOARDING TEXT FILED
class SignUpTextField extends StatelessWidget {
  const SignUpTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.validatorText,
    required this.type,
  });
  final String hintText;
  final TextEditingController controller;
  final String validatorText;
  final SignUpOnboardingTextFieldEnum type;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      height: 60,
      child: TextFormField(
        inputFormatters: (type == SignUpOnboardingTextFieldEnum.userName) ||
                (type == SignUpOnboardingTextFieldEnum.password)
            ? [
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ]
            : [],
        style: Theme.of(context).textTheme.labelLarge,
        cursorColor: Theme.of(context).colorScheme.tertiary2,
        obscureText: type == SignUpOnboardingTextFieldEnum.password,
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText, // pass the hint text parameter here
        ),
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
}

enum SignInOnboardingTextFieldEnum { userName, password }

class SignInTextField extends StatelessWidget {
  const SignInTextField({
    super.key,
    required this.hintText,
    required this.controller,
    required this.validatorText,
    required this.type,
  });
  final String hintText;
  final TextEditingController controller;
  final String validatorText;
  final SignInOnboardingTextFieldEnum type;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      child: TextFormField(
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
        ],
        obscureText: type == SignInOnboardingTextFieldEnum.password,
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText, // pass the hint text parameter here
        ),
        style: Theme.of(context).textTheme.labelLarge,
        cursorColor: Theme.of(context).colorScheme.tertiary2,
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
}
