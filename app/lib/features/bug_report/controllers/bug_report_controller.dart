import 'dart:io';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BugReportController extends GetxController {
  List<String> tags = [];
  String errorText = '';
  bool isSubmitting = false;

  void setTags(List<String> values) {
    tags = values;
  }

  Future<String?> report(
    BuildContext context,
    String description,
    bool withLog,
    String? screenshotPath,
  ) async {
    // validate issue description
    if (description.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Empty description'),
          content: const Text('Please enter the issue description'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return '';
    }

    // validate issue tag
    if (tags.isEmpty) {
      bool? res = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Empty tag'),
          content: const Text('Will you submit without any tag?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (res == false) {
        return '';
      }
    }

    isSubmitting = true;
    final sdk = await EffektioSdk.instance;
    final reportUrl = await sdk.reportBug(
      description,
      tags.isEmpty ? null : tags.join(','),
      withLog,
      screenshotPath,
    );
    if (screenshotPath != null) {
      await File(screenshotPath).delete();
    }
    isSubmitting = false;
    return reportUrl;
  }
}
