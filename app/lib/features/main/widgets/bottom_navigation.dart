import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/features/main/providers/navigation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const Duration _bottomSheetEnterDuration = Duration(milliseconds: 250);
const Duration _bottomSheetExitDuration = Duration(milliseconds: 200);
const Curve _modalBottomSheetCurve = decelerateEasing;
const double _minFlingVelocity = 700.0;
const double _closeProgressThreshold = 0.5;
const double _defaultScrollControlDisabledMaxHeightRatio = 9.0 / 16.0;

class BottomNavigationWidget extends StatefulHookConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const BottomNavigationWidget({super.key, required this.navigationShell});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState
    extends ConsumerState<BottomNavigationWidget> {
  void toggleOpen() {}

  @override
  Widget build(BuildContext context) {
    final keyboardVisibility = ref.watch(keyboardVisibleProvider);
    if (keyboardVisibility.valueOrNull != false) {
      return const SizedBox.shrink();
    }
    final NavigationBarThemeData naviSheetTheme =
        Theme.of(context).navigationBarTheme;
    final bool useMaterial3 = Theme.of(context).useMaterial3;
    final BottomSheetThemeData defaults = useMaterial3
        ? _BottomSheetDefaultsM3(context)
        : const BottomSheetThemeData();
    final Color? color = naviSheetTheme.backgroundColor;
    final _controller =
        useAnimationController(duration: const Duration(seconds: 3));
    return Material(
      surfaceTintColor: color,
      child: Container(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: Column(
          children: [
            _DragHandle(
              onTap: () => toggleOpen(),
              materialState: const {},
            ),
            SizedBox(
              height: 50,
              child: Stack(
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
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysHide,
                    selectedIndex: widget.navigationShell.currentIndex,
                    onDestinationSelected: (index) {
                      widget.navigationShell.goBranch(
                        index,
                        initialLocation:
                            index == widget.navigationShell.currentIndex,
                      );
                    },
                    destinations: bottomBarItems,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({
    required this.onTap,
    required this.materialState,
    this.dragHandleColor,
    this.dragHandleSize,
  });

  final VoidCallback? onTap;
  final Set<WidgetState> materialState;
  final Color? dragHandleColor;
  final Size? dragHandleSize;

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData bottomSheetTheme =
        Theme.of(context).bottomSheetTheme;
    final BottomSheetThemeData m3Defaults = _BottomSheetDefaultsM3(context);
    final Size handleSize = dragHandleSize ??
        bottomSheetTheme.dragHandleSize ??
        m3Defaults.dragHandleSize!;

    return Semantics(
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      container: true,
      onTap: onTap,
      child: SizedBox(
        width: handleSize.width * 2,
        height: handleSize.height * 2,
        child: Center(
          child: Container(
            height: handleSize.height,
            width: handleSize.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(handleSize.height / 2),
              color: WidgetStateProperty.resolveAs<Color?>(
                    dragHandleColor,
                    materialState,
                  ) ??
                  WidgetStateProperty.resolveAs<Color?>(
                    bottomSheetTheme.dragHandleColor,
                    materialState,
                  ) ??
                  m3Defaults.dragHandleColor,
            ),
          ),
        ),
      ),
    );
  }
}
// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

class _BottomSheetDefaultsM3 extends BottomSheetThemeData {
  _BottomSheetDefaultsM3(this.context)
      : super(
          elevation: 1.0,
          modalElevation: 1.0,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.0))),
          constraints: const BoxConstraints(maxWidth: 640),
        );

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get backgroundColor => _colors.surfaceContainerLow;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get dragHandleColor => _colors.onSurfaceVariant;

  @override
  Size? get dragHandleSize => const Size(32, 4);

  @override
  BoxConstraints? get constraints => const BoxConstraints(maxWidth: 640.0);
}
