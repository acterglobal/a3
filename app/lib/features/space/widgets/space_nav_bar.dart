import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SpaceNavItem { overview, pins, events, chats, spaces, members }

class SpaceNavBar extends StatefulWidget {
  final String spaceId;
  final int selectedIndex;

  const SpaceNavBar({
    super.key,
    required this.selectedIndex,
    required this.spaceId,
  });

  @override
  State<SpaceNavBar> createState() => _SpaceNavBarState();
}

class _SpaceNavBarState extends State<SpaceNavBar>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(
        length: 6,
        vsync: this,
        initialIndex: widget.selectedIndex,
        animationDuration: const Duration(milliseconds: 500));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCols = constraints.maxWidth < (150 * 6);
        int minItemWidth = useCols ? 90 : 150;
        final minTotalWidth = minItemWidth * 6;
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
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TabBar(
            controller: _tabController,
            isScrollable: scrollBar,
            labelColor: Colors.white,
            labelStyle: useCols
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.bodySmall,
            indicatorColor: Theme.of(context).colorScheme.tertiary,
            padding: EdgeInsets.zero,
            tabs: [
              tabViewItemUI(
                title: 'Overview',
                iconData: Atlas.layout_half_thin,
                onTap: () => context.goNamed(
                  Routes.space.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
              tabViewItemUI(
                title: 'Pins',
                iconData: Atlas.pin_thin,
                onTap: () => context.goNamed(
                  Routes.spacePins.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
              tabViewItemUI(
                title: 'Events',
                iconData: Atlas.calendar_schedule_thin,
                onTap: () => context.goNamed(
                  Routes.spaceEvents.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
              tabViewItemUI(
                title: 'Chats',
                iconData: Atlas.chats_thin,
                onTap: () => context.goNamed(
                  Routes.spaceChats.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
              tabViewItemUI(
                title: 'Spaces',
                iconData: Atlas.connection_thin,
                onTap: () => context.goNamed(
                  Routes.spaceRelatedSpaces.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
              tabViewItemUI(
                title: 'Members',
                iconData: Atlas.group_team_collective_thin,
                onTap: () => context.goNamed(
                  Routes.spaceMembers.name,
                  pathParameters: {'spaceId': widget.spaceId},
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget tabViewItemUI({
    required String title,
    required IconData iconData,
    Function()? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Tab(
          text: title,
          icon: Icon(iconData),
        ),
      ),
    );
  }
}
