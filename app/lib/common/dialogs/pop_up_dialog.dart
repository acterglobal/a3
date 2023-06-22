import 'package:flutter/material.dart';

void popUpDialog({
  required BuildContext context,
  required Widget? title,
  Widget? subtitle,
  Widget? description,
  String? btnText,
  void Function()? onPressedBtn,
  void Function()? onPressedBtn2,
  String? btn2Text,
  Color? btnColor,
  Color? btn2Color,
  Color? btnBorderColor,
  bool isLoader = false,
}) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              title ?? const SizedBox.shrink(),
              const SizedBox(height: 15),
              subtitle ?? const SizedBox.shrink(),
              const SizedBox(height: 15),
              description ?? const SizedBox.shrink(),
              isLoader
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          btnText != null
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: btnColor,
                                    side: BorderSide(
                                      color:
                                          btnBorderColor ?? Colors.transparent,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: onPressedBtn ?? () {},
                                  child: Text(btnText),
                                )
                              : const SizedBox.shrink(),
                          btn2Text != null
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: btn2Color,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: onPressedBtn2 ?? () {},
                                  child: Text(btn2Text),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      );
    },
  );
}
