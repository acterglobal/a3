import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/quick_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:go_router/go_router.dart';

class BottomNavigationWidget extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationWidget({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<BottomNavigationWidget> createState() =>
      _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState
    extends ConsumerState<BottomNavigationWidget> {
  bool isShow = false;

  @override
  Widget build(BuildContext context) {
    return bottomNavigationWidget();
  }

  Widget bottomNavigationWidget() {
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
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(30.0),
              topLeft: Radius.circular(30.0),
            ),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              if (details.delta.dy < 0) {
                isShow = !isShow;
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Divider(
                  indent: 180,
                  endIndent: 180,
                  thickness: 2,
                ),
                BottomNavigationBar(
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  currentIndex: widget.navigationShell.currentIndex,
                  onTap: (index) {
                    widget.navigationShell.goBranch(
                      index,
                      initialLocation:
                          index == widget.navigationShell.currentIndex,
                    );
                  },
                  items: bottomBarItems,
                  type: BottomNavigationBarType.fixed,
                ),
                if (isShow) const QuickActionButtons(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
