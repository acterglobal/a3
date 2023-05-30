import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:flutter/material.dart';

class InSettings extends StatelessWidget {
  final Widget child;
  const InSettings({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 700) {
          return Row(
            children: [
              const SizedBox(
                width: 350,
                child: SettingsMenu(),
              ),
              Expanded(child: child),
            ],
          );
        }
        return child;
      },
    );
  }
}
