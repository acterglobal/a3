import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_media_state.freezed.dart';

///Extension Method for easy comparison
extension AttachmentMediaLoadingStateGetters on AttachmentMediaLoadingState {
  bool get isLoading => this is _AttachmentMediaLoadingStateLoading;
}

@freezed
class AttachmentMediaLoadingState with _$AttachmentMediaLoadingState {
  ///Loading
  const factory AttachmentMediaLoadingState.loading() =
      _AttachmentMediaLoadingStateLoading;

  ///Data
  const factory AttachmentMediaLoadingState.loaded() =
      _AttachmentMediaLoadingStateLoaded;

  ///Error
  const factory AttachmentMediaLoadingState.error([String? error]) =
      _AttachmentMediaLoadingStateError;
}

@freezed
class AttachmentMediaState with _$AttachmentMediaState {
  const factory AttachmentMediaState({
    @Default(AttachmentMediaLoadingState.loading())
    AttachmentMediaLoadingState mediaLoadingState,
    File? mediaFile,
    @Default(false) bool isDownloading,
  }) = _AttachmentMediaState;
}
