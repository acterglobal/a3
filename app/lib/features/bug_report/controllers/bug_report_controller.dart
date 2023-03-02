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

  Future<bool> report(
    BuildContext context,
    String text,
    bool withLog,
    String? screenshotPath,
  ) async {
    // validate issue text
    if (text.isEmpty) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Empty text'),
          content: const Text('Please enter the issue text'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ok'),
            ),
          ],
        ),
      );
      return false;
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
        return false;
      }
    }

    isSubmitting = true;
    final sdk = await EffektioSdk.instance;
    final res = await sdk.reportBug(
      text,
      tags.join(','),
      withLog,
      screenshotPath,
    );
    if (screenshotPath != null) {
      await File(screenshotPath).delete();
    }
    isSubmitting = false;
    return res;
  }
}
