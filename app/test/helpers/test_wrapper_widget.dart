import 'package:acter/common/themes/acter_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_trigger_auto_complete/acter_trigger_autocomplete.dart';

class InActerContextTestWrapper extends StatelessWidget {
  final Widget child;

  const InActerContextTestWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final easyLoadingBuilder = EasyLoading.init();
    EasyLoading.instance.toastPosition = EasyLoadingToastPosition.bottom;
    return Portal(
      child: MaterialApp(
        theme: ActerTheme.theme,
        title: 'Acter',
        home: child,
        builder:
            (context, child) => easyLoadingBuilder(
              context,
              Overlay(
                initialEntries: [
                  OverlayEntry(builder: (context) => Scaffold(body: child)),
                ],
              ),
            ),
        locale: const Locale('en', 'US'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        // MaterialApp contains our top-level Navigator
      ),
    );
  }
}
