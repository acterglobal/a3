import 'package:acter/common/tutorial_dialogs/space_overview_tutorials/space_overview_tutorials.dart';
import 'package:acter/features/space/providers/space_navbar_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::space::top_nav_bar');

class TopNavBar extends ConsumerStatefulWidget {
  static const moreTabsKey = Key('space-more-tabs');
  final String spaceId;

  const TopNavBar({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopNavBarState();
}

class _TopNavBarState extends ConsumerState<TopNavBar> {
  final spaceOverviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    spaceOverviewTutorials(
      context: context,
      spaceOverviewKey: spaceOverviewKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabsProvider(widget.spaceId));
    return tabState.when(
      skipLoadingOnReload: true,
      data: (tabState) => buildTabs(context, tabState),
      error: (error, stack) {
        _log.severe('Error generating space tabs menu', error, stack);
        return buildError(context, error.toString());
      },
      loading: () => buildLoading(context),
    );
  }

  Widget buildContainer(BuildContext context, Widget child) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        color: Theme.of(context).colorScheme.background,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: child,
    );
  }

  Widget buildError(BuildContext context, String error) {
    return buildContainer(
      context,
      Text(
        L10n.of(context).errorLoadingNavigationMenu(error),
      ),
    );
  }

  Widget buildLoading(BuildContext context) {
    return buildContainer(
      context,
      LayoutBuilder(
        key: spaceOverviewKey,
        builder: (context, constraints) {
          final useCols = constraints.maxWidth < 500;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              3,
              (idx) {
                final children = [
                  const Skeletonizer(child: Icon(Icons.abc)),
                  const Skeletonizer(child: Text('something')),
                ];
                return useCols
                    ? SizedBox(
                        width: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: children,
                      );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildTabs(BuildContext context, List<TabEntry> tabs) {
    int selectedIdx =
        ref.watch(selectedTabIdxProvider(widget.spaceId)).valueOrNull ?? 0;
    return LayoutBuilder(
      key: spaceOverviewKey,
      builder: (context, constraints) {
        final useCols = constraints.maxWidth <= ((150 * tabs.length) + 20);
        int minItemWidth = useCols ? 90 : 150;
        final minTotalWidth = minItemWidth * tabs.length;
        bool hasMore = false;
        int maxItems = tabs.length;
        if (minTotalWidth > constraints.maxWidth) {
          hasMore = true;
          maxItems = ((constraints.maxWidth - 100) / minItemWidth).floor();
          if (selectedIdx >= maxItems) {
            // we have an item in the selection that is in the popupmenu,
            // swap the last item in the list with it
            final toSwitch = tabs.removeAt(selectedIdx);
            tabs.insert(maxItems - 1, toSwitch);
            selectedIdx = maxItems - 1;
          }
        }
        return buildContainer(
          context,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(
                maxItems,
                (index) {
                  final color = index == selectedIdx
                      ? Theme.of(context).colorScheme.secondary
                      : (Theme.of(context).tabBarTheme.labelColor ??
                          Theme.of(context).colorScheme.primary);
                  final tabItem = tabs[index];
                  return buildRegularListItem(
                    context,
                    tabItem,
                    color,
                    useCols ? minItemWidth.toDouble() : null,
                  );
                },
              ),
              if (hasMore) buildMoreMenu(tabs.sublist(maxItems)),
            ],
          ),
        );
      },
    );
  }

  Widget buildRegularListItem(
    BuildContext context,
    TabEntry tabItem,
    Color color,
    double? itemWidth,
  ) {
    final children = [
      tabItem.makeIcon(context, color),
      itemWidth != null ? const SizedBox(height: 5) : const SizedBox(width: 10),
      Text(tabItem.label, style: TextStyle(color: color)),
    ];
    return InkWell(
      key: tabItem.key,
      onTap: () => context.pushReplacementNamed(
        tabItem.target.name,
        pathParameters: {'spaceId': widget.spaceId},
      ),
      child: itemWidth != null
          ? SizedBox(
              width: itemWidth,
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
  }

  Widget buildMoreMenu(List<TabEntry> items) {
    return PopupMenuButton(
      key: TopNavBar.moreTabsKey,
      itemBuilder: (ctx) => items
          .map(
            (tabItem) => PopupMenuItem(
              key: tabItem.key,
              child: Row(
                children: [
                  tabItem.makeIcon(context, Colors.white),
                  const SizedBox(width: 10),
                  Text(tabItem.label),
                ],
              ),
              onTap: () => context.pushReplacementNamed(
                tabItem.target.name,
                pathParameters: {'spaceId': widget.spaceId},
              ),
            ),
          )
          .toList(),
    );
  }
}
