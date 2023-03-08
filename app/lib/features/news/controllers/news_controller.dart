import 'package:effektio/features/home/repositories/client_repository.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' show News;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    StateNotifierProvider<NewsListNotifier, AsyncValue<List<News>>>(
  (ref) => NewsListNotifier(ref),
);

class NewsListNotifier extends StateNotifier<AsyncValue<List<News>>> {
  final Ref ref;
  NewsListNotifier(this.ref) : super(const AsyncData([])) {
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    state = const AsyncLoading();
    final client = ref.read(clientRepositoryProvider);
    state = await AsyncValue.guard(() async {
      return await client.news();
    });
  }
}
