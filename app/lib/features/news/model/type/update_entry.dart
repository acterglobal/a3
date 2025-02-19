
import 'package:acter/features/news/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

bool isStory(UpdateEntry inner) => inner is UpdateStory;

/// Abstract base class for entries that contain slides
abstract class UpdateEntry {
  /// The number of slides in this entry
  int slidesCount();

  /// Get all slides
  List<UpdateSlide> slides();

  /// Get a specific slide by position
  UpdateSlide? getSlide(int pos);

  /// Get the room ID this entry belongs to
  RoomId roomId();

  /// Get the sender ID
  UserId sender();
 
  /// Get the event ID
  EventId eventId();

  /// Get the timestamp of this event
  int originServerTs();
  
  // Check if the current user can redact this item
  Future<bool> canRedact();

  /// Get the reaction manager
  Future<ReactionManager> reactions();

  /// Get the read receipt manager
  Future<ReadReceiptsManager> readReceipts();

  /// Get the comment manager
  Future<CommentsManager> comments();

  /// Get the internal reference object
  Future<RefDetails> refDetails();
}


/// A news entry
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
      return UpdateNewsEntrySlide(slide);
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
  List<UpdateSlide> slides() => inner.slides()
      .map((slide) => UpdateNewsEntrySlide(slide))
      .toList();

  @override
  int slidesCount() => inner.slidesCount();
}


/// A news entry
class UpdateStoryEntry extends UpdateEntry {
  final StoryEntry inner;

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
      return UpdateNewsEntrySlide(slide);
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
  List<UpdateSlide> slides() => inner.slides()
      .map((slide) => UpdateNewsEntrySlide(slide))
      .toList();

  @override
  int slidesCount() => inner.slidesCount();
}
