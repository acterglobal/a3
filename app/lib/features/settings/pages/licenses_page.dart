import 'package:acter/features/settings/widgets/in_settings.dart';
import 'package:flutter/material.dart';

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const InSettings(child: LicensePage());
  }
}
