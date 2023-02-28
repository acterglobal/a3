import 'package:effektio/features/bug_report/controllers/bug_report_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class SelectTag extends StatelessWidget {
  final List<String> tags = [
    'bug',
    'build',
    'ci-build-android',
    'ci-build-ios',
    'dependencies',
    'design needed',
    'documentation',
    'e2ee',
    'flutter',
    'good first issue',
    'help wanted',
    'infrastructure',
    'rust',
    's-calendar',
    's-chat',
    's-documents',
    's-gallery',
    's-group-budgeting',
    's-integration',
    's-news',
    's-pins',
    's-polls',
    's-tasks',
    's-vault',
    't-android',
    't-desktop',
    't-ios',
    't-web',
    'UI/UX',
  ];

  SelectTag({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BugReportController>(
      builder: (BugReportController controller) {
        return MultiSelectDialogField(
          items: tags.map((e) => MultiSelectItem(e, e)).toList(),
          listType: MultiSelectListType.CHIP,
          onConfirm: (values) {
            controller.setTags(values);
          },
          searchable: true,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade50,
              width: 1.2,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          buttonText: const Text(
            'Select',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          buttonIcon: const Icon(
            Icons.arrow_downward,
            color: Colors.white,
          ),
        );
      },
    );
  }
}
