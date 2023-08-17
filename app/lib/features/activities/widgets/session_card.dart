import 'dart:core';

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
    final fields = ['Unverified'];
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
    final displayName = deviceRecord.displayName();
    if (displayName != null) {
      fields.add(displayName);
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: const Icon(Icons.question_mark_rounded),
        title: Text(deviceRecord.displayName() ?? ''),
        subtitle: Text(fields.join(' - ')),
        trailing: const Icon(Icons.arrow_right),
        onTap: () => onTap(context),
      ),
    );
  }

  void onTap(BuildContext context) {}
}
