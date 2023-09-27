import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class AllTasksDone extends StatelessWidget {
  const AllTasksDone({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: Center(
        child: Column(
          children: [
            Text(
              'Congrats!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Icon(
                Atlas.check_circle_thin,
                size: 50.0,
                color: Theme.of(context).colorScheme.success,
              ),
            ),
            Text(
              'you are done with all your tasks!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'see open tasks',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
