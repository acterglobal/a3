import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/features/main/providers/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationWidget extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const BottomNavigationWidget({super.key, required this.navigationShell});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState
    extends ConsumerState<BottomNavigationWidget> {
  @override
  Widget build(BuildContext context) {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    if (keyboardVisibility.valueOrNull != false) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        SizedBox(
          height: 50,
          child: Row(
            children: bottomBarItems
                .map(
                  (bottomBarNav) => Expanded(
                    child: Center(
                      child: SizedBox(
                        key: bottomBarNav.tutorialGlobalKey,
                        height: 40,
                        width: 40,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: bottomBarItems,
        ),
      ],
    );
  }
}
