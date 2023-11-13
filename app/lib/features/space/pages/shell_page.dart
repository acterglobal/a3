import 'package:acter/features/space/widgets/shell_header.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceShell extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;

  const SpaceShell({
    super.key,
    required this.spaceIdOrAlias,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceShellState();
}

class _SpaceShellState extends ConsumerState<SpaceShell> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SpaceToolbar(spaceId: widget.spaceIdOrAlias),
        ShellHeader(widget.spaceIdOrAlias),
        TopNavBar(spaceId: widget.spaceIdOrAlias),
      ],
    );
  }
}
