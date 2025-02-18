import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';

/// A wrapper for AbstractSettingsTiles
class CustomSettingsTile extends StatelessWidget
    implements AbstractSettingsTile {
  final Widget child;

  const CustomSettingsTile({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
