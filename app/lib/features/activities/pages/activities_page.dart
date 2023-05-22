import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/providers/profile_provider.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final account = ref.watch(accountProfileProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Activities',
            sectionColor: Colors.pink.shade600,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  showNotYetImplementedMsg(
                    context,
                    'Activities filters not yet implemented',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Atlas.gear_thin),
                onPressed: () {
                  showNotYetImplementedMsg(
                    context,
                    'Notifications Settings page not yet implemented',
                  );
                },
              ),
            ],
            expandedContent: const Text(
              'All the important stuff requiring your attention can be found here',
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: Center(
                child: Text('Scroll to see the SliverAppBar in effect.'),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return Container(
                  color: index.isOdd
                      ? Colors.amber.shade900
                      : Colors.green.shade900,
                  height: 100.0,
                  child: Center(
                    child: Text('$index', textScaleFactor: 5),
                  ),
                );
              },
              childCount: 20,
            ),
          ),
        ],
      ),
    );
  }
}
