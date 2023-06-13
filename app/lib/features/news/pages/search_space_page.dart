import 'package:acter/common/widgets/custom_app_bar.dart';
import 'package:acter/common/widgets/search_widget.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/news/widgets/space_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchSpacePage extends ConsumerStatefulWidget {
  const SearchSpacePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SearchSpacePageState();
}

class _SearchSpacePageState extends ConsumerState<SearchSpacePage> {
  final TextEditingController searchController = TextEditingController();

  void selectionUpdate(int index) {
    final spaceNotifier = ref.read(selectedSpaceProvider.notifier);
    spaceNotifier.update((state) => ref.watch(searchSpaceProvider)[index]);

    final searchNotifier = ref.read(isSearchingProvider.notifier);
    searchNotifier.update((state) => false);

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final spaceItems = ref.watch(searchSpaceProvider);
    final isSearch = ref.watch(isSearchingProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: const Text('Search Space'),
        context: context,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SearchWidget(
              searchController: searchController,
              onChanged: (value) =>
                  ref.watch(searchSpaceProvider.notifier).filterSpace(value),
            ),
            isSearch
                ? spaceItems.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: spaceItems.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SpaceItem(
                            title:
                                spaceItems[index].spaceProfileData.displayName,
                            members: spaceItems[index].activeMembers,
                            callback: () => selectionUpdate(index),
                            avatar: spaceItems[index]
                                .spaceProfileData
                                .getAvatarImage(),
                          ),
                        ),
                      )
                    : Center(
                        heightFactor: 15,
                        child: Text(
                          'No Space found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        ref.read(searchSpaceProvider.notifier).items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SpaceItem(
                        title: ref
                            .read(searchSpaceProvider.notifier)
                            .items[index]
                            .spaceProfileData
                            .displayName,
                        members: ref
                            .read(searchSpaceProvider.notifier)
                            .items[index]
                            .activeMembers,
                        avatar: ref
                            .read(searchSpaceProvider.notifier)
                            .items[index]
                            .spaceProfileData
                            .getAvatarImage(),
                        callback: () => selectionUpdate(index),
                      ),
                    ),
                  )
          ],
        ),
      ),
    );
  }
}
