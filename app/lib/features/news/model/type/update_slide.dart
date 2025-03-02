import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

abstract class UpdateSlide {
  String typeStr();

  String uniqueId();

  FfiListObjRef references();

  Colorize? colors();

  MsgContent msgContent();

  Future<FfiBufferUint8> sourceBinary(ThumbnailSize? thumbSize);
}

class UpdateNewsSlide extends UpdateSlide {
  final NewsSlide inner;

  UpdateNewsSlide(this.inner);

  @override
  Colorize? colors() => inner.colors();

  @override
  MsgContent msgContent() => inner.msgContent();

  @override
  FfiListObjRef references() => inner.references();

  @override
  Future<FfiBufferUint8> sourceBinary(ThumbnailSize? thumbSize) =>
      inner.sourceBinary(thumbSize);

  @override
  String typeStr() => inner.typeStr();

  @override
  String uniqueId() => inner.uniqueId();
}

class UpdateStorySlide extends UpdateSlide {
  final StorySlide inner;

  UpdateStorySlide(this.inner);

  @override
  Colorize? colors() => inner.colors();

  @override
  MsgContent msgContent() => inner.msgContent();

  @override
  FfiListObjRef references() => inner.references();

  @override
  Future<FfiBufferUint8> sourceBinary(ThumbnailSize? thumbSize) =>
      inner.sourceBinary(thumbSize);

  @override
  String typeStr() => inner.typeStr();

  @override
  String uniqueId() => inner.uniqueId();
}
