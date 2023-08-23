import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';

class TabsState {
  final List<TabEntry> tabs;
  final TabController ctrl;
  const TabsState(this.tabs, this.ctrl);
}

class TopNavBar extends ConsumerStatefulWidget {
  final String spaceId;

  const TopNavBar({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopNavBarState();
}

class _TopNavBarState extends ConsumerState<TopNavBar>
    with TickerProviderStateMixin {
  late final AutoDisposeFutureProviderFamily<TabsState, BuildContext>
      recentWatchScreenTabStateTestProvider;

  @override
  void initState() {
    super.initState();
    recentWatchScreenTabStateTestProvider = FutureProvider.autoDispose
        .family<TabsState, BuildContext>((ref, context) async {
      final tabs = await ref.watch(tabsProvider(widget.spaceId).future);
      final ctrl = TabController(
        length: tabs.length,
        vsync: this,
        initialIndex: 0,
      );
      ref.onDispose(() {
        ctrl.dispose(); // we need to clean this up.
      });
      return TabsState(tabs, ctrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(recentWatchScreenTabStateTestProvider(context));
    final selectedIndex = ref.watch(selectedTabIdxProvider(widget.spaceId));
    return tabState.when(
      data: (tabState) {
        final tabController = tabState.ctrl;
        final tabs = tabState.tabs;
        tabController.animateTo(selectedIndex.valueOrNull ?? 0);

        return LayoutBuilder(
          builder: (context, constraints) {
            final useCols = constraints.maxWidth < (150 * tabs.length);
            int minItemWidth = useCols ? 90 : 150;
            final minTotalWidth = minItemWidth * tabs.length;
            bool scrollBar = false;
            if (minTotalWidth > constraints.maxWidth) {
              scrollBar = true;
            }
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                color: Theme.of(context).colorScheme.background,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TabBar(
                controller: tabController,
                isScrollable: scrollBar,
                onTap: (idx) {
                  final target = tabs[idx].target;
                  context.goNamed(
                    target,
                    pathParameters: {'spaceId': widget.spaceId},
                  );
                },
                labelStyle: useCols
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.bodySmall,
                labelColor: Colors.white,
                labelPadding: useCols ? const EdgeInsets.all(8) : null,
                indicatorColor: Theme.of(context).colorScheme.tertiary,
                tabs: List.generate(
                  tabs.length,
                  (index) {
                    final tabItem = tabs[index];
                    final children = [
                      tabItem.makeIcon(context),
                      useCols
                          ? const SizedBox(height: 5)
                          : const SizedBox(width: 10),
                      Text(tabItem.label),
                    ];
                    return Tab(
                      key: tabItem.key,
                      child: useCols
                          ? SizedBox(
                              width: minItemWidth.toDouble(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: children,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: children,
                            ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
      error: (e, stack) => Text('Error loading navigation menu: $e'),
      loading: () => const SizedBox(height: 50),
    );
  }
}
