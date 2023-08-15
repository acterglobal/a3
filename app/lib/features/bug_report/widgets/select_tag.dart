import 'package:acter/features/bug_report/providers/bug_report_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_selector/flutter_custom_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// rageshake supports only single tag for issue.
// when it supports multi tag, we can convert single selector into multi selector,
// because flutter_custom_selector provides both single and multi.

Color labelColor = Colors.white; // customized color
Color errorColor = const Color(0xFFFF5858);

class SelectTag extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final reportNotifier = ref.read(bugReportProvider.notifier);
    return CustomSingleSelectField(
      items: tags,
      title: 'Select issue tag',
      onSelectionDone: (value) {
        reportNotifier.setTags([value.toString()]);
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(15),
        errorBorder:
            inputFieldBorder(color: Theme.of(context).colorScheme.error),
        errorMaxLines: 2,
        errorStyle: Theme.of(context).textTheme.labelSmall,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        labelText: 'Select issue tag',
        labelStyle: Theme.of(context).textTheme.labelMedium,
        suffixIcon: const Icon(Atlas.arrow_down_circle),
        suffixIconColor: Colors.white,
        enabledBorder: inputFieldBorder(),
        border: inputFieldBorder(),
        focusedBorder: inputFieldBorder(),
        focusedErrorBorder:
            inputFieldBorder(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
