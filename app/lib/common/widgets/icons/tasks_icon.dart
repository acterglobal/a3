import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TasksIcon extends StatelessWidget {
  const TasksIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SvgPicture.asset(
        'assets/images/tasks.svg',
        semanticsLabel: 'tasks',
        height: 28,
        width: 28,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
