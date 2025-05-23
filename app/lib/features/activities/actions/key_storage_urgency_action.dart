import 'package:flutter/material.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';

enum KeyStorageUrgency {
  normal,    // 0-3 days
  warning,   // 3-7 days
  critical,  // 7+ days
}

class KeyStorageUrgencyAction {
  static KeyStorageUrgency getUrgencyLevel(int timestamp) {
    if (timestamp == 0) return KeyStorageUrgency.normal;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final daysSinceStored = (now - timestamp) ~/ (24 * 60 * 60);

    if (daysSinceStored <= 3) return KeyStorageUrgency.normal;
    if (daysSinceStored <= 7) return KeyStorageUrgency.warning;
    return KeyStorageUrgency.critical;
  }

  static Color getUrgencyColor(BuildContext context, KeyStorageUrgency urgency) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (urgency) {
      KeyStorageUrgency.normal => colorScheme.primary,
      KeyStorageUrgency.warning => warningColor,
      KeyStorageUrgency.critical => colorScheme.error,
    };
  }
} 