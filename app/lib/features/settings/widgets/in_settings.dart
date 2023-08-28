import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:flutter/material.dart';

class InSettings extends StatelessWidget {
  final Widget child;
  const InSettings({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Flexible(flex: 1, child: SettingsMenu()),
              Flexible(flex: 2, child: child),
            ],
          );
        }
        return child;
      },
    );
  }
}
