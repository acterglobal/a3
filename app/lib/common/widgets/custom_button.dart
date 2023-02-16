import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final String title;

  const CustomButton({
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
