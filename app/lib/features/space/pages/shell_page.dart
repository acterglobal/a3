import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/shell_header.dart';
import 'package:acter/features/space/widgets/space_nav_bar.dart';
import 'package:acter/features/space/widgets/space_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpaceShell extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  final SpaceNavItem spaceNavItem;

  const SpaceShell({
    super.key,
    required this.spaceIdOrAlias,
    required this.spaceNavItem,
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
        //TopNavBar(spaceId: widget.spaceIdOrAlias),
        SpaceNavBar(
          spaceId: widget.spaceIdOrAlias,
          selectedIndex: getSpaceTabIndex(),
        ),
      ],
    );
  }

  int getSpaceTabIndex() {
    switch (widget.spaceNavItem) {
      case SpaceNavItem.overview:
        return 0;
      case SpaceNavItem.pins:
        return 1;
      case SpaceNavItem.events:
        return 2;
      case SpaceNavItem.chats:
        return 3;
      case SpaceNavItem.spaces:
        return 4;
      case SpaceNavItem.members:
        return 5;
      default:
        return 0;
    }
  }
}
