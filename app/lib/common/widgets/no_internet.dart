import 'package:acter/common/themes/seperated_themes.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';

OverlaySupportEntry showNoInternetNotification() {
  return showSimpleNotification(
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.wifi_off,
          color: NotificationPopUpTheme.networkTextColor,
        ),
        SizedBox(
          width: 12,
        ),
        Text(
          'Network connectivity limited or unavailable',
          style: NotificationPopUpTheme.networkTitleStyle,
        ),
      ],
    ),
    background: NotificationPopUpTheme.networkBackgroundColor,
    slideDismissDirection: DismissDirection.up,
    duration: const Duration(seconds: 10),
  );
}
