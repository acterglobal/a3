import 'dart:io';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ng/widgets/events/audio_message_event.dart';
import 'package:acter/features/chat_ng/widgets/message_timestamp_widget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_audio_event_providers.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('AudioMessageEvent Tests', () {
    const roomId = 'test-room';
    const messageId = 'test-message';
    const fileName = 'audio.mp3';
    const fileSize = 1024;
    const mimeType = 'audio/mpeg';

    late MockMsgContent mockContent;

    setUp(() {
      mockContent = MockMsgContent(
        bodyText: fileName,
        sizeValue: fileSize,
        mimeTypeValue: mimeType,
      );
    });

    group('Media Download States', () {
      testWidgets('renders download button when media file is not downloaded', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byType(AudioMessageEvent), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
        expect(find.text(fileName), findsOneWidget);
      });

      testWidgets('renders loading indicator when media is downloading', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier(
                mediaChatLoadingState: const MediaChatLoadingState.loading(),
                isDownloading: true,
              );
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byType(AudioMessageEvent), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text(fileName), findsOneWidget);
      });

      testWidgets('renders play button when media file is downloaded', (
        tester,
      ) async {
        final mockFile = File('audio.mp3');

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier(
                mediaChatLoadingState: const MediaChatLoadingState.loaded(),
                mediaFile: mockFile,
                isDownloading: false,
              );
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byType(AudioMessageEvent), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        expect(find.text(fileName), findsOneWidget);
      });

      testWidgets('renders error state when media download fails', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier(
                mediaChatLoadingState: const MediaChatLoadingState.error(
                  'Download failed',
                ),
                isDownloading: false,
              );
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byType(AudioMessageEvent), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
        expect(find.text(fileName), findsOneWidget);
      });
    });

    group('Audio Player States', () {
      testWidgets('shows play button when audio is stopped', (tester) async {
        final mockFile = File('audio.mp3');

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier(
                mediaChatLoadingState: const MediaChatLoadingState.loaded(),
                mediaFile: mockFile,
              );
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('shows pause button when audio is playing for this message', (
        tester,
      ) async {
        final mockFile = File('audio.mp3');

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier(
                mediaChatLoadingState: const MediaChatLoadingState.loaded(),
                mediaFile: mockFile,
                isDownloading: false,
              );
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.playing, messageId: messageId),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.byIcon(Icons.pause), findsOneWidget);
      });

      testWidgets(
        'shows play button when audio is playing for different message',
        (tester) async {
          final mockFile = File('audio.mp3');

          await tester.pumpProviderWidget(
            overrides: [
              mediaChatStateProvider((
                roomId: roomId,
                messageId: messageId,
              )).overrideWith((ref) {
                return MockMediaChatNotifier(
                  mediaChatLoadingState: const MediaChatLoadingState.loaded(),
                  mediaFile: mockFile,
                  isDownloading: false,
                );
              }),
              audioPlayerStateProvider.overrideWith(
                (ref) => (
                  state: PlayerState.playing,
                  messageId: 'different-message',
                ),
              ),
            ],
            child: AudioMessageEvent(
              roomId: roomId,
              messageId: messageId,
              content: mockContent,
            ),
          );

          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
        },
      );
    });

    group('UI Elements and Layout', () {
      testWidgets('displays file name correctly', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.text(fileName), findsOneWidget);
      });

      testWidgets('handles empty file name', (tester) async {
        final emptyContent = MockMsgContent(
          bodyText: '',
          sizeValue: fileSize,
          mimeTypeValue: mimeType,
        );

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: emptyContent,
          ),
        );

        expect(find.byType(AudioMessageEvent), findsOneWidget);
        expect(find.byIcon(Icons.download), findsOneWidget);
        expect(find.text(''), findsOneWidget);
      });

      testWidgets('displays file size when available', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
          ),
        );

        expect(find.text(formatBytes(fileSize)), findsOneWidget);
      });

      testWidgets('handles zero file size', (tester) async {
        final zeroSizeContent = MockMsgContent(
          bodyText: fileName,
          sizeValue: 0,
          mimeTypeValue: mimeType,
        );

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: zeroSizeContent,
          ),
        );

        expect(find.text('0 B'), findsOneWidget);
      });

      testWidgets('does not display file size when size is null', (
        tester,
      ) async {
        final contentWithoutSize = MockMsgContent(
          bodyText: fileName,
          sizeValue: null,
          mimeTypeValue: mimeType,
        );

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: contentWithoutSize,
          ),
        );

        expect(find.text('1.0 KB'), findsNothing);
      });

      testWidgets('displays timestamp when provided', (tester) async {
        const timestamp = 1640995200000; // Example timestamp

        await tester.pumpProviderWidget(
          overrides: [
            mediaChatStateProvider((
              roomId: roomId,
              messageId: messageId,
            )).overrideWith((ref) {
              return MockMediaChatNotifier();
            }),
            audioPlayerStateProvider.overrideWith(
              (ref) => (state: PlayerState.stopped, messageId: null),
            ),
          ],
          child: AudioMessageEvent(
            roomId: roomId,
            messageId: messageId,
            content: mockContent,
            timestamp: timestamp,
          ),
        );

        expect(find.byType(MessageTimestampWidget), findsOneWidget);
      });
    });
  });
}
