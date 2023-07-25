import 'package:acter/common/themes/app_theme.dart';
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
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
              } else if (states.contains(MaterialState.disabled)) {
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                );
              }
              return RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              );
            },
          ),
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Theme.of(context).colorScheme.primaryContainer;
              } else if (states.contains(MaterialState.disabled)) {
                return Theme.of(context).colorScheme.neutral3;
              }
              return Theme.of(context).colorScheme.primaryContainer;
            },
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Theme.of(context).colorScheme.onPrimaryContainer;
              } else if (states.contains(MaterialState.disabled)) {
                return Theme.of(context).colorScheme.neutral3;
              }
              return Theme.of(context).colorScheme.onPrimaryContainer;
            },
          ),
        ),
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }
}
