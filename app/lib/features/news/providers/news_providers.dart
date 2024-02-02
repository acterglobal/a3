import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show NewsEntry;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsListProvider =
    AsyncNotifierProvider.autoDispose<AsyncNewsListNotifier, List<NewsEntry>>(
  () => AsyncNewsListNotifier(),
);
