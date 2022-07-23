import 'package:example/custom/custom_example_provider.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class CustomExample extends StatelessWidget {
  const CustomExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: RiverPagedBuilder<String, User>(
        firstPageKey: '',
        provider: customExampleProvider,
        pullToRefresh: true,
        itemBuilder: (context, item, index) => ListTile(
          leading: Image.network(item.profilePicture),
          title: Text(item.name),
        ),
        pagedBuilder: (controller, builder) => PagedGridView(
          pagingController: controller,
          builderDelegate: builder,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
        ),
      ),
    );
  }
}
