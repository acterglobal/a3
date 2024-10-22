import 'package:acter/common/drag_handle_widget.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/quick_action_buttons.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationWidget extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationWidget({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    final showQuickActions = ref.watch(quickActionVisibilityProvider);
    if (keyboardVisibility.valueOrNull != false) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        tutorialScreenUI(),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20.0),
              topLeft: Radius.circular(20.0),
            ),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dy < 0) {
                ref.watch(quickActionVisibilityProvider.notifier).state = true;
              } else {
                ref.watch(quickActionVisibilityProvider.notifier).state = false;
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const DragHandleWidget(),
                const SizedBox(height: 6),
                bottomNavNar(ref),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: showQuickActions ? 150 : 0,
                  child: const QuickActionButtons(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget tutorialScreenUI() {
    return SizedBox(
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
    );
  }

  Widget bottomNavNar(WidgetRef ref) {
    return BottomNavigationBar(
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: navigationShell.currentIndex,
      onTap: (index) {
        ref.read(quickActionVisibilityProvider.notifier).state = false;
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      items: bottomBarItems,
      type: BottomNavigationBarType.fixed,
    );
  }
}
