import 'dart:core';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final DeviceRecord deviceRecord;

  const SessionCard({
    Key? key,
    required this.deviceRecord,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVerified = deviceRecord.verified();
    final fields = [isVerified ? 'Verified' : 'Unverified'];
    final lastSeenTs = deviceRecord.lastSeenTs();
    if (lastSeenTs != null) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        lastSeenTs,
        isUtc: true,
      );
      fields.add(dateTime.toString());
    }
    final lastSeenIp = deviceRecord.lastSeenIp();
    if (lastSeenIp != null) {
      fields.add(lastSeenIp);
    }
    fields.add(deviceRecord.deviceId().toString());
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: isVerified
            ? Icon(
                Icons.verified_rounded,
                color: Theme.of(context).colorScheme.success,
              )
            : Icon(
                Icons.question_mark_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
        title: Text(deviceRecord.displayName() ?? ''),
        subtitle: Text(fields.join(' - ')),
        trailing: const Icon(Icons.arrow_right),
        onTap: () => onTap(context),
      ),
    );
  }

  void onTap(BuildContext context) {}
}
