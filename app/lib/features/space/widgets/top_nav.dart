import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class TopNavBar extends StatefulWidget {
  final bool isDesktop;
  const TopNavBar({super.key, required this.isDesktop});

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> tabLabels = [
    'Overview',
    'Chat',
    'Groups',
    'Events',
    'Tasks'
  ];
  final List<Icon> tabIcons = const [
    Icon(Atlas.layout_half_thin),
    Icon(Atlas.chats_thin),
    Icon(Atlas.connection_thin),
    Icon(Atlas.calendar_dots_thin),
    Icon(Atlas.check_folder_thin),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
        color: Theme.of(context).colorScheme.background,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TabBar(
        controller: _tabController,
        labelStyle: Theme.of(context).textTheme.bodySmall,
        labelColor: Colors.white,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 30),
        indicatorColor: Theme.of(context).colorScheme.tertiary,
        tabs: List.generate(
          5,
          (index) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                tabIcons[index],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(tabLabels[index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
