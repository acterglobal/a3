import 'package:flutter/material.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';

enum KeyStorageUrgency {
  normal,    // 0-3 days
  warning,   // 3-7 days
  critical,  // 7+ days
}

Color getUrgencyColor(BuildContext context, KeyStorageUrgency urgency) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (urgency) {
    KeyStorageUrgency.normal => colorScheme.primary,
    KeyStorageUrgency.warning => warningColor,
    KeyStorageUrgency.critical => colorScheme.error,
  };
} 