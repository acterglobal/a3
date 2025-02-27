import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';

class TasksIcon extends StatelessWidget {
  final double size;

  const TasksIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SvgPicture.asset(
        'assets/images/tasks.svg',
        semanticsLabel: L10n.of(context).tasks,
        height: size,
        width: size,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.onSurface,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
