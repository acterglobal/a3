import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomOnbaordingButton extends StatelessWidget {
  final void Function()? onPressed;
  final String title;

  const CustomOnbaordingButton({
    Key? key,
    required this.onPressed,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 18),
          ),
          shape: MaterialStateProperty.resolveWith<OutlinedBorder>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.pink),
                );
              } else if (states.contains(MaterialState.disabled)) {
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.pink),
              );
            },
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return ToDoTheme.primaryColor;
              } else if (states.contains(MaterialState.disabled)) {
                return ToDoTheme.textFieldColor;
              }
              return ToDoTheme.primaryColor;
            },
          ),
        ),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

enum SignUpOnboardingTextFieldEnum { name, userName, password, token }

// ON BOARDING TEXT FILED
Widget signUpOnboardingTextField(
  String hintText,
  TextEditingController controller,
  String validatorText,
  SignUpOnboardingTextFieldEnum type,
) {
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
        border: InputBorder.none,
        hintText: hintText, // pass the hint text parameter here
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
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
    margin: const EdgeInsets.symmetric(horizontal: 20),
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
        contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
        border: InputBorder.none,
        hintText: hintText, // pass the hint text parameter here
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      style: const TextStyle(color: Colors.white),
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
