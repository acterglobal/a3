import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AsyncNewsListNotifier extends AutoDisposeAsyncNotifier<List<NewsEntry>> {
  late Stream<void> _listener;

  @override
  Future<List<NewsEntry>> build() async {
    final client = ref.read(clientProvider)!;
    _listener = client.subscribe('news');
    _listener.forEach((_e) async {
      print(" --- - - ----------------- new subscribe received");
      state = await AsyncValue.guard(() => _fetchNews());
    });
    return await _fetchNews();
  }

  Future<List<NewsEntry>> _fetchNews() async {
    print(" -------      refreshing news");
    final client = ref.read(clientProvider);
    var entries = await client!.latestNewsEntries(25).then((v) => v.toList());
    return entries;
  }
}
