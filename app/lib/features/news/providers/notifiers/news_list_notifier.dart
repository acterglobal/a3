import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsListStateNotifier extends StateNotifier<AsyncValue<List<NewsEntry>>> {
  final Ref ref;
  NewsListStateNotifier(this.ref) : super(const AsyncData([])) {
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    state = const AsyncLoading();
    final client = ref.read(clientProvider);
    state = await AsyncValue.guard(() async {
      var entries = await client!.latestNewsEntries(25).then((v) => v.toList());
      return entries;
    });
  }
}
