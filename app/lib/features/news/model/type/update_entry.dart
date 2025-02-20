import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

bool isStory(UpdateEntry inner) => inner is UpdateStoryEntry;

abstract class UpdateEntry {
  int slidesCount();

  List<UpdateSlide> slides();

  UpdateSlide? getSlide(int pos);

  RoomId roomId();

  UserId sender();

  EventId eventId();

  int originServerTs();

  Future<bool> canRedact();

  Future<ReactionManager> reactions();

  Future<ReadReceiptsManager> readReceipts();

  Future<CommentsManager> comments();

  Future<RefDetails> refDetails();
}

class UpdateNewsEntry extends UpdateEntry {
  final NewsEntry inner;

  UpdateNewsEntry(this.inner);

  @override
  Future<bool> canRedact() => inner.canRedact();

  @override
  Future<CommentsManager> comments() => inner.comments();

  @override
  EventId eventId() => inner.eventId();

  @override
  UpdateSlide? getSlide(int pos) {
    final slide = inner.getSlide(pos);
    if (slide != null) {
      return UpdateNewsSlide(slide);
    }
    return null;
  }

  @override
  int originServerTs() => inner.originServerTs();

  @override
  Future<ReactionManager> reactions() => inner.reactions();

  @override
  Future<ReadReceiptsManager> readReceipts() => inner.readReceipts();

  @override
  Future<RefDetails> refDetails() => inner.refDetails();

  @override
  RoomId roomId() => inner.roomId();

  @override
  UserId sender() => inner.sender();

  @override
  List<UpdateSlide> slides() =>
      inner.slides().map((slide) => UpdateNewsSlide(slide)).toList();

  @override
  int slidesCount() => inner.slidesCount();
}

class UpdateStoryEntry extends UpdateEntry {
  final Story inner;

  UpdateStoryEntry(this.inner);

  @override
  Future<bool> canRedact() => inner.canRedact();

  @override
  Future<CommentsManager> comments() => inner.comments();

  @override
  EventId eventId() => inner.eventId();

  @override
  UpdateSlide? getSlide(int pos) {
    final slide = inner.getSlide(pos);
    if (slide != null) {
      return UpdateStorySlide(slide);
    }
    return null;
  }

  @override
  int originServerTs() => inner.originServerTs();

  @override
  Future<ReactionManager> reactions() => inner.reactions();

  @override
  Future<ReadReceiptsManager> readReceipts() => inner.readReceipts();

  @override
  RoomId roomId() => inner.roomId();

  @override
  UserId sender() => inner.sender();

  @override
  List<UpdateSlide> slides() =>
      inner.slides().map((slide) => UpdateStorySlide(slide)).toList();

  @override
  int slidesCount() => inner.slidesCount();

  @override
  Future<RefDetails> refDetails() {
    throw UnimplementedError();
  }
}
