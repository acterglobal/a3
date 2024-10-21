import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/quick_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:go_router/go_router.dart';

Widget bottomNavigationWidget(
  BuildContext context,
  WidgetRef ref,
  StatefulNavigationShell navigationShell,
) {
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
      GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dy < 0) {
            showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => const QuickActionButtons(),
            );
          }
        },
        child: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          items: bottomBarItems,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    ],
  );
}
