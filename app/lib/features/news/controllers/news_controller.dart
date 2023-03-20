import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    StateNotifierProvider<NewsListNotifier, AsyncValue<List<NewsEntry>>>(
  (ref) => NewsListNotifier(ref),
);

class NewsListNotifier extends StateNotifier<AsyncValue<List<NewsEntry>>> {
  final Ref ref;
  NewsListNotifier(this.ref) : super(const AsyncData([])) {
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    state = const AsyncLoading();
    final client = ref.read(homeStateProvider);
    state = await AsyncValue.guard(() async {
      return await client!.latestNews(25).then((ffiList) => ffiList.toList());
    });
  }
}
