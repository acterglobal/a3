import 'dart:io';

import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/features/bug_report/controllers/bug_report_controller.dart';
import 'package:acter/features/bug_report/widgets/select_tag.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BugReportPage extends StatefulWidget {
  final String? imagePath;

  const BugReportPage({Key? key, this.imagePath}) : super(key: key);

  @override
  _BugReportState createState() => _BugReportState();
}

class _BugReportState extends State<BugReportPage> {
  final formKey = GlobalKey<FormState>();
  final bugReportController = Get.put(BugReportController());
  String description = '';
  bool withLog = false;
  bool withScreenshot = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    Get.delete<BugReportController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ToDoTheme.backgroundGradient2Color,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Atlas.arrow_left_circle,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Issue description',
              style: AuthTheme.authBodyStyle,
            ),
            const SizedBox(height: 10),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() {
                description = value;
              }),
            ),
            const SizedBox(height: 10),
            const Text(
              'Issue tag(s)',
              style: AuthTheme.authBodyStyle,
            ),
            const SizedBox(height: 10),
            SelectTag(),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text(
                'Including log file',
                style: AuthTheme.authBodyStyle,
              ),
              value: withLog,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() => withLog = value);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text(
                'Including screenshot',
                style: AuthTheme.authBodyStyle,
              ),
              value: withScreenshot,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() => withScreenshot = value);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              enabled: widget.imagePath != null,
            ),
            const SizedBox(height: 10),
            if (withScreenshot)
              Image.file(
                File(widget.imagePath!),
                width: MediaQuery.of(context).size.width * 0.8,
                errorBuilder: (
                  BuildContext ctx,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Text('Could not load image due to $error');
                },
              ),
            if (withScreenshot) const SizedBox(height: 10),
            const Divider(
              color: ToDoTheme.dividerColor,
              endIndent: 10,
              indent: 10,
            ),
            const SizedBox(height: 10),
            GetBuilder<BugReportController>(
              id: 'submit',
              builder: (BugReportController controller) {
                if (controller.isSubmitting) {
                  return const CircularProgressIndicator(
                    color: AppCommonTheme.primaryColor,
                  );
                }
                return CustomButton(
                  onPressed: () async {
                    String? reportUrl = await controller.report(
                      context,
                      description,
                      withLog,
                      withScreenshot ? widget.imagePath : null,
                    );
                    String msg = 'Error occurred in bug report';
                    if (reportUrl != null) {
                      String? issueId = getIssueId(reportUrl);
                      msg = 'Reported the bug successfully! (#$issueId)';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                    Navigator.pop(context);
                  },
                  title: 'Submit',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
