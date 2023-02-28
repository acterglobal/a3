import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/widgets/custom_button.dart';
import 'package:effektio/features/bug_report/controllers/bug_report_controller.dart';
import 'package:effektio/features/bug_report/widgets/select_tag.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({Key? key}) : super(key: key);

  @override
  _BugReportState createState() => _BugReportState();
}

class _BugReportState extends State<BugReportPage> {
  final formKey = GlobalKey<FormState>();
  final bugReportController = Get.put(BugReportController());
  String text = '';
  bool withLog = false;

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
          onTap: () => Get.back(),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: ToDoTheme.toDoDecoration,
        height: MediaQuery.of(context).size.height * (1 - 0.12),
        padding: const EdgeInsets.all(16),
        child: GetBuilder<BugReportController>(
          builder: (BugReportController controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Issue text',
                  style: AuthTheme.authBodyStyle,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => setState(() {
                    text = value;
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
                const Divider(
                  color: ToDoTheme.dividerColor,
                  endIndent: 10,
                  indent: 10,
                ),
                const SizedBox(height: 10),
                controller.isSubmitting
                    ? const CircularProgressIndicator(
                        color: AppCommonTheme.primaryColor,
                      )
                    : CustomButton(
                        onPressed: () async {
                          bool result = await controller.report(
                            context,
                            text,
                            withLog,
                          );
                          String msg = result
                              ? 'Reported the bug successfully!'
                              : 'Error occurred in bug report';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                          Get.back();
                        },
                        title: 'Submit',
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
