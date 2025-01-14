import 'package:acter/features/news/providers/notifiers/news_list_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_basics.dart';
import 'mock_read_receipt_providers.dart';

class MockAsyncNewsListNotifier
    extends FamilyAsyncNotifier<List<NewsEntry>, String?>
    with Mock
    implements AsyncNewsListNotifier {
  final List<NewsEntry>? news;
  MockAsyncNewsListNotifier({this.news});

  @override
  Future<List<NewsEntry>> build(String? arg) async => news ?? [];
}

class MockNewsSlide extends Mock implements NewsSlide {
  @override
  FfiListObjRef references() => MockFfiListObjRef();
}

class MockFfiListNewsSlide extends Mock implements FfiListNewsSlide {
  final List<MockNewsSlide> inner;

  MockFfiListNewsSlide({required this.inner});

  @override
  List<NewsSlide> toList({bool growable = true}) => inner;
}

class MockNewsEntry extends Mock implements NewsEntry {
  final List<MockNewsSlide> slides_;
  final String roomId_;
  final String eventId_;
  final int whenAt;

  MockNewsEntry({
    this.slides_ = const [],
    this.roomId_ = 'roomId',
    this.eventId_ = 'eventId',
    this.whenAt = 1,
  });

  @override
  int slidesCount() => slides_.length;

  @override
  MockFfiListNewsSlide slides() => MockFfiListNewsSlide(inner: slides_);

  @override
  MockRoomId roomId() => MockRoomId(roomId_);
  @override
  MockEventId eventId() => MockEventId(eventId_);

  @override
  int originServerTs() => whenAt;

  @override
  Future<ReadReceiptsManager> readReceipts() =>
      Future.value(MockReadReceiptsManager(count: 10));
}
