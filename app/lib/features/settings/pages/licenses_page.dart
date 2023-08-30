import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:flutter/material.dart';

class SettingsLicensesPage extends StatelessWidget {
  const SettingsLicensesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WithSidebar(sidebar: SettingsMenu(), child: LicensePage());
  }
}
