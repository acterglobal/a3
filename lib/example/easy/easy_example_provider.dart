
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';


class Post {
  final int id;
  final String title;
  final String image;
  const Post({ required this.id, required this.title, required this.image });
}

class EasyExampleNotifier extends PagedNotifier<int, Post> {

  EasyExampleNotifier():
    super(
      load: (page, limit) => Future.delayed(const Duration(seconds: 2), () {
        // This simulates a network call to an api that returns paginated posts
        return [
          const Post(id: 1, title: "My first work", image: "https://www.mywebsite.com/image1"),
          const Post(id: 2, title: "My second work", image: "https://www.mywebsite.com/image2"),
          const Post(id: 3, title: "My third work", image: "https://www.mywebsite.com/image3"),
        ];
      }),
      nextPageKeyBuilder: NextPageKeyBuilderDefault.mysqlPagination,
    );
  
  // Super simple example of custom methods of the StateNotifier
  void add(Post post) {
    state = state.copyWith(records: [ ...(state.records ?? []), post ]);
  }
  void delete(Post post) {
    state = state.copyWith(records: [ ...(state.records ?? []) ]..remove(post));
  }
  
}

final easyExampleProvider = StateNotifierProvider<EasyExampleNotifier, PagedState<int, Post>>((_) => EasyExampleNotifier());