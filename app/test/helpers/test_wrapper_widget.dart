import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';

class InActerContextTestWrapper extends StatelessWidget {
  final Widget child;

  const InActerContextTestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: MaterialApp(
        theme: ActerTheme.theme,
        title: 'Acter',
        builder: (context, other) => Scaffold(body: child),
        locale: const Locale('en', 'US'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        // MaterialApp contains our top-level Navigator
      ),
    );
  }
}
