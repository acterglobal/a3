import 'package:effektio/features/bug_report/controllers/bug_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:get/get.dart';

// rageshake supports only single tag for issue.
// when it supports multi tag, we can convert single selector into multi selector,
// because flutter_custom_selector provides both single and multi.

Color labelColor = Colors.white; // customized color
Color errorColor = const Color(0xFFFF5858);

class SelectTag extends StatelessWidget {
  final List<String> tags = [
    'bug',
    'documentation',
    'duplicate',
    'enhancement',
    'good first issue',
    'help wanted',
    'invalid',
    'question',
    'wontfix',
  ];

  SelectTag({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BugReportController>(
      builder: (BugReportController controller) {
        return CustomSingleSelectField(
          items: tags,
          title: 'Select issue tag',
          onSelectionDone: (value) {
            controller.setTags([value.toString()]);
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(15),
            errorBorder: inputFieldBorder(color: errorColor),
            errorMaxLines: 2,
            errorStyle: defaultTextStyle(
              color: errorColor,
              fontSize: 11,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            labelText: 'Select issue tag',
            labelStyle: defaultTextStyle(
              color: labelColor,
              fontSize: 16,
            ),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_outlined),
            suffixIconColor: Colors.white,
            enabledBorder: inputFieldBorder(),
            border: inputFieldBorder(),
            focusedBorder: inputFieldBorder(),
            focusedErrorBorder: inputFieldBorder(color: errorColor),
          ),
        );
      },
    );
  }
}
