import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

OverlaySupportEntry showNoInternetNotification() {
  return showSimpleNotification(
    const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off),
        SizedBox(width: 12),
        Text('Network connectivity limited or unavailable'),
      ],
    ),
    slideDismissDirection: DismissDirection.up,
    duration: const Duration(seconds: 10),
  );
}
