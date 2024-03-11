import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/providers/navigation.dart';
import 'package:acter/features/home/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:screenshot/screenshot.dart';

final _log = Logger('a3::home::home_body');

ScreenshotController screenshotController = ScreenshotController();

// we use ConsumerStatefulWidget, because we don't call setState here but we need dispose fn
class HomeBody extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final bool keyboardVisible;
  final bool hasFirstSynced;

  const HomeBody({
    super.key,
    required this.navigationShell,
    required this.keyboardVisible,
    required this.hasFirstSynced,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => HomeBodyState();
}

class HomeBodyState extends ConsumerState<HomeBody> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    super.dispose();

    final crossSigning = ref.read(syncStateProvider.notifier).crossSigning;
    crossSigning.removeEventFilter();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(syncStateProvider, (prev, next) {
      _log.info('initialSync - ${next.initialSync}');
      if (next.initialSync) return;
      final crossSigning = ref.read(syncStateProvider.notifier).crossSigning;
      crossSigning.installEventFilter(context);
    });

    final bottomBarNav = ref.watch(bottomBarNavProvider(context));
    return CallbackShortcuts(
      bindings: <LogicalKeySet, VoidCallback>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () {
          context.pushNamed(Routes.quickJump.name);
        },
      },
      child: KeyboardDismissOnTap(
        // close keyboard if clicking somewhere else
        child: Scaffold(
          body: Screenshot(
            controller: screenshotController,
            child: AdaptiveLayout(
              key: _key,
              topNavigation: !widget.hasFirstSynced
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig?>{
                        Breakpoints.smallAndUp: SlotLayout.from(
                          key: const Key('LoadingIndicator'),
                          builder: (BuildContext ctx) =>
                              const LinearProgressIndicator(
                            semanticsLabel: 'Loading first sync',
                          ),
                        ),
                      },
                    )
                  : null,
              primaryNavigation: isDesktop
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig?>{
                        // adapt layout according to platform.
                        Breakpoints.small: SlotLayout.from(
                          key: const Key('primaryNavigation'),
                          builder: (BuildContext ctx) => SidebarWidget(
                            labelType: NavigationRailLabelType.selected,
                            navigationShell: widget.navigationShell,
                          ),
                        ),
                        Breakpoints.mediumAndUp: SlotLayout.from(
                          key: const Key('primaryNavigation'),
                          builder: (BuildContext ctx) => SidebarWidget(
                            labelType: NavigationRailLabelType.all,
                            navigationShell: widget.navigationShell,
                          ),
                        ),
                      },
                    )
                  : null,
              body: SlotLayout(
                config: <Breakpoint, SlotLayoutConfig>{
                  Breakpoints.smallAndUp: SlotLayout.from(
                    key: const Key('Body Small'),
                    builder: (BuildContext ctx) => widget.navigationShell,
                  ),
                },
              ),
              bottomNavigation: !isDesktop && !widget.keyboardVisible
                  ? SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig>{
                        //In desktop, we have ability to adjust windows res,
                        // adjust to navbar as primary to smaller views.
                        Breakpoints.smallAndUp: SlotLayout.from(
                          key: Keys.mainNav,
                          inAnimation: AdaptiveScaffold.bottomToTop,
                          outAnimation: AdaptiveScaffold.topToBottom,
                          builder: (BuildContext ctx) => BottomNavigationBar(
                            showSelectedLabels: false,
                            showUnselectedLabels: false,
                            currentIndex: widget.navigationShell.currentIndex,
                            onTap: (index) {
                              widget.navigationShell.goBranch(
                                index,
                                initialLocation: index ==
                                    widget.navigationShell.currentIndex,
                              );
                            },
                            items: bottomBarNav,
                            type: BottomNavigationBarType.fixed,
                          ),
                        ),
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void handleBottomNavigation(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
