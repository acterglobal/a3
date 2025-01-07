import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockAsyncNewsListNotifier
    extends FamilyAsyncNotifier<List<NewsEntry>, String?>
    with Mock
    implements AsyncNewsListNotifier {
  final List<NewsEntry>? news;
  MockAsyncNewsListNotifier({this.news});

  @override
  Future<List<NewsEntry>> build(String? arg) async => news ?? [];
}

class MockNewsEntry extends Mock implements NewsEntry {
  final String id;

  MockNewsEntry({
    this.id = 'id',
  });

  @override
  String getRoomIdStr() => id;
}
