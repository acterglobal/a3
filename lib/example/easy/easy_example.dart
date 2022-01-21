import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/example/easy/easy_example_provider.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class EasyExample extends StatelessWidget {
  const EasyExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: RiverPagedBuilder<int, Post>(
        // the first page we will ask
        firstPageKey: 0,
        // The [StateNotifierProvider] that holds the logic and the list of Posts
        provider: easyExampleProvider,
        // a function that build a single Post
        itemBuilder: (context, item, index) => ListTile(
          leading: Image.network(item.image),
          title: Text(item.title),
        ),
        // The type of list we want to render
        // This can be any of the [infinite_scroll_pagination] widgets
        pagedBuilder: (controller, builder) => PagedListView(pagingController: controller, builderDelegate: builder),
      ),
    );
  }
}