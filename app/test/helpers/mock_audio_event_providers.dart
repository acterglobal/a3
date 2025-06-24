import 'dart:io';

import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/notifiers/media_chat_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockMsgContent extends Mock implements MsgContent {
  final String bodyText;
  final int? sizeValue;
  final String? mimeTypeValue;

  MockMsgContent({required this.bodyText, this.sizeValue, this.mimeTypeValue});

  @override
  String body() => bodyText;

  @override
  int? size() => sizeValue;

  @override
  String? mimetype() => mimeTypeValue;
}

class MockMediaChatNotifier extends StateNotifier<MediaChatState>
    with Mock
    implements MediaChatNotifier {
  final MediaChatLoadingState mediaChatLoadingState;
  final File? mediaFile;
  final bool isDownloading;

  MockMediaChatNotifier({
    this.mediaChatLoadingState = const MediaChatLoadingState.notYetStarted(),
    this.mediaFile,
    this.isDownloading = false,
  }) : super(
         MediaChatState(
           mediaChatLoadingState: mediaChatLoadingState,
           mediaFile: mediaFile,
           isDownloading: isDownloading,
         ),
       );
}
