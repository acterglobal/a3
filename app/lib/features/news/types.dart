import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

abstract class UpdateSlide {
  typeStr() {}

  colors() {}
}

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

  /// Check if the current user can redact this item
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
class UpdateNewsEntrySlide extends UpdateSlide {
  final NewsSlide inner;

  UpdateNewsEntrySlide(this.inner);
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
  int originServerTs() {
    // TODO: implement originServerTs
    throw UnimplementedError();
  }

  @override
  Future<ReactionManager> reactions() {
    // TODO: implement reactions
    throw UnimplementedError();
  }

  @override
  Future<ReadReceiptsManager> readReceipts() {
    // TODO: implement readReceipts
    throw UnimplementedError();
  }

  @override
  Future<RefDetails> refDetails() {
    // TODO: implement refDetails
    throw UnimplementedError();
  }

  @override
  RoomId roomId() {
    // TODO: implement roomId
    throw UnimplementedError();
  }

  @override
  UserId sender() {
    // TODO: implement sender
    throw UnimplementedError();
  }

  @override
  List<UpdateSlide> slides() {
    // TODO: implement slides
    throw UnimplementedError();
  }

  @override
  int slidesCount() {
    // TODO: implement slidesCount
    throw UnimplementedError();
  }

  // ... rest of NewsEntry implementation ...
}

/// A story entry
class UpdateStory extends UpdateEntry {
  final Story inner;

  UpdateStory(this.inner);

  // ... rest of Story implementation ...
}

bool isStory(UpdateEntry inner) => inner is UpdateStory;
