import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const WithSidebar(sidebar: SettingsPage(), child: LicensePage());
  }
}
