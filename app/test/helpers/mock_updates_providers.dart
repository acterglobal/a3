import 'package:acter/features/news/model/type/update_entry.dart';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_basics.dart';
import 'mock_read_receipt_providers.dart';

class MockUpdateSlide extends Mock implements UpdateSlide {
  @override
  FfiListObjRef references() => MockFfiListObjRef();
}

class MockUpdatesEntry extends Mock implements UpdateEntry {
  final List<MockUpdateSlide> slides_;
  final String roomId_;
  final String eventId_;
  final int whenAt;

  MockUpdatesEntry({
    this.slides_ = const [],
    this.roomId_ = 'roomId',
    this.eventId_ = 'eventId',
    this.whenAt = 1,
  });

  @override
  int slidesCount() => slides_.length;

  @override
  List<UpdateSlide> slides() => slides_;

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
