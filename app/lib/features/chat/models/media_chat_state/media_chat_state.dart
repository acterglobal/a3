import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_chat_state.freezed.dart';

///Extension Method for easy comparison
extension MediaChatLoadingStateGetters on MediaChatLoadingState {
  bool get isLoading => this is _MediaChatLoadingStateLoading;
}

@freezed
class MediaChatLoadingState with _$MediaChatLoadingState {
  /// Not Yet Started
  const factory MediaChatLoadingState.notYetStarted() =
      _MediaChatLoadingStateNotYetStarted;

  ///Loading
  const factory MediaChatLoadingState.loading() = _MediaChatLoadingStateLoading;

  ///Data
  const factory MediaChatLoadingState.loaded() = _MediaChatLoadingStateLoaded;

  ///Error
  const factory MediaChatLoadingState.error([String? error]) =
      _MediaChatLoadingStateError;
}

@freezed
class MediaChatState with _$MediaChatState {
  const factory MediaChatState({
    @Default(MediaChatLoadingState.loading())
    MediaChatLoadingState mediaChatLoadingState,
    File? mediaFile,
    File? videoThumbnailFile,
    @Default(false) bool isDownloading,
  }) = _MediaChatState;
}
