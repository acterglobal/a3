import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class AllTasksDone extends StatelessWidget {
  const AllTasksDone({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 450,
      child: Center(
        child: Column(
          children: [
            Text(lang.congrats, style: textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                Atlas.check_circle_thin,
                size: 50.0,
                color: colorScheme.success,
              ),
            ),
            Text(lang.youAreDoneWithAllYourTasks, style: textTheme.bodyMedium),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(lang.seeOpenTasks, style: textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
