import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/keyboard_visbility_provider.dart';
import 'package:acter/common/providers/notifiers/room_notifiers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/features/chat_ng/dialogs/message_actions.dart';
import 'package:acter/features/chat_ng/globals.dart';
import 'package:acter/features/chat_ng/pages/chat_room.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/models/chat_editor_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_editor_notifier.dart';
import 'package:acter/features/chat_ng/widgets/events/message_event_item.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../helpers/font_loader.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_client_provider.dart';
import '../../../helpers/test_util.dart';
import '../../comments/mock_data/mock_message_content.dart';
import '../diff_applier_test.dart';
import '../messages/chat_message_test.dart';

// Mock ChatEditorNotifier for testing
class MockChatEditorNotifier extends ChatEditorNotifier {
  @override
  ChatEditorState build() => const ChatEditorState(
    selectedMsgItem: null,
    actionType: MessageAction.none,
  );
}

class MockRoomAvatarInfoNotifier extends RoomAvatarInfoNotifier {
  @override
  AvatarInfo build(String roomId) => MockAvatarInfo(uniqueId: roomId);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Define screen sizes for different platforms
  const mobileSize = Size(440, 956); // iPhone 16 Pro Max dimensions
  const desktopSize = Size(1024, 768); // Standard desktop dimensions

  // Mock the platform channels to prevent MissingPluginException
  const channel = MethodChannel('keyboardHeightEventChannel');
  binding.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async => null,
  );

  group('Message Actions Dialog Golden Tests', () {
    const myUserId = '@me:example.com';
    const otherUserId = '@other:example.com';
    const roomId = '!room:example.com';

    // Test messages with different lengths
    final shortMessage = 'Hello!';
    final mediumMessage =
        'This is a medium length message that spans about two lines when displayed in the chat bubble.';
    final longMessage =
        'This is a longer message that will definitely span multiple lines. It contains more text to ensure we test how the dialog handles longer content while maintaining proper alignment and spacing of all components.';
    final superLongMessage =
        'This is an extremely long message that will require scrolling to view completely. ' *
        20;

    Future<void> showMessageActionsDialog(
      WidgetTester tester, {
      required String message,
      required bool isMe,
    }) async {
      final messageItem = MockTimelineEventItem(
        mockMsgType: 'm.text',
        mockSender: isMe ? myUserId : otherUserId,
        mockMsgContent: MockMsgContent(bodyText: message),
      );

      final timelineItem = MockTimelineItem(
        id: 'test-message',
        mockEventItem: messageItem,
      );

      await tester.pumpProviderWidget(
        overrides: [
          myUserIdStrProvider.overrideWith((ref) => myUserId),
          isDirectChatProvider.overrideWith((ref, roomId) => false),
          messageReadReceiptsProvider.overrideWith((ref, item) => {}),
          messageReactionsProvider.overrideWith((ref, item) => []),
          memberDisplayNameProvider.overrideWith((ref, args) => args.userId),
          keyboardVisibleProvider.overrideWith((ref) => Stream.value(false)),
          chatEditorStateProvider.overrideWith(() => MockChatEditorNotifier()),
          sdkProvider.overrideWith((ref) => MockActerSdk()),
          clientProvider.overrideWith(
            () => MockClientNotifier(client: MockClient()),
          ),
          chatProvider.overrideWith(() => MockAsyncConvoNotifier()),
          chatComposerDraftProvider.overrideWith(
            (ref, roomId) => MockComposeDraft(),
          ),
          renderableChatMessagesProvider.overrideWith(
            (ref, roomId) => [message],
          ),
          chatRoomMessageProvider.overrideWith((ref, roomMsgId) {
            final uniqueId = roomMsgId.uniqueId;
            return switch (uniqueId) {
              'test-message' => timelineItem,
              _ => null,
            };
          }),
          roomAvatarInfoProvider.overrideWith(
            () => MockRoomAvatarInfoNotifier(),
          ),
          parentAvatarInfosProvider.overrideWith(
            (ref, roomId) => Future.value([]),
          ),
          membersIdsProvider(roomId).overrideWith((ref) => Future.value([])),
          memberAvatarInfoProvider.overrideWith(
            (ref, args) => MockAvatarInfo(uniqueId: args.userId),
          ),

          roomMembershipProvider(
            roomId,
          ).overrideWith((ref) => Future.value(null)),
        ],
        child: Builder(
          builder: (context) {
            final messageWidget = ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: MessageEventItem(
                roomId: roomId,
                messageId: timelineItem.id,
                item: messageItem,
                isMe: isMe,
                isDM: false,
                canRedact: true,
                isFirstMessageBySender: true,
                isLastMessageBySender: true,
                isLastMessage: true,
              ),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (context.mounted) {
                await showGeneralDialog(
                  context: context,
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          MessageActions(
                            animation: animation,
                            canRedact: true,
                            item: messageItem,
                            roomId: roomId,
                            messageId: timelineItem.id,
                            messageWidget: messageWidget,
                            isMe: isMe,
                          ),
                );
              }
            });
            return ChatRoomNgPage(key: chatRoomKey, roomId: roomId);
          },
        ),
      );

      // Wait for the widget tree to be built and the dialog to appear
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<void> expectGoldenMatch(
      WidgetTester tester,
      String baseGoldenPath,
      Size screenSize,
    ) async {
      final platform = screenSize == mobileSize ? 'mobile' : 'desktop';
      final goldenPath = baseGoldenPath.replaceAll('.png', '_$platform.png');

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(goldenPath),
      );

      final dialogFinder = find.byType(MessageActions);
      if (dialogFinder.evaluate().isNotEmpty) {
        final dialogContext = tester.element(dialogFinder);
        Navigator.of(dialogContext).pop();
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    Future<void> runPlatformTest({
      required WidgetTester tester,
      required String message,
      required bool isMe,
      required String baseGoldenPath,
      required Size screenSize,
    }) async {
      await tester.binding.setSurfaceSize(screenSize);
      await tester.pump(const Duration(milliseconds: 300));
      await showMessageActionsDialog(tester, message: message, isMe: isMe);
      await tester.pump(const Duration(milliseconds: 300));
      await expectGoldenMatch(tester, baseGoldenPath, screenSize);
    }

    group('Mobile Tests', () {
      testWidgets('Own message - short text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: shortMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_short.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Own message - medium text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: mediumMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_medium.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Own message - long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: longMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_long.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Own message - super long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: superLongMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_super_long.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Other user message - short text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: shortMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_short.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Other user message - medium text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: mediumMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_medium.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Other user message - long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: longMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_long.png',
          screenSize: mobileSize,
        );
      });

      testWidgets('Other user message - super long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: superLongMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_super_long.png',
          screenSize: mobileSize,
        );
      });
    });

    group('Desktop Tests', () {
      testWidgets('Own message - short text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: shortMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_short.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Own message - medium text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: mediumMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_medium.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Own message - long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: longMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_long.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Own message - super long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: superLongMessage,
          isMe: true,
          baseGoldenPath: 'goldens/message_actions_own_super_long.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Other user message - short text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: shortMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_short.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Other user message - medium text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: mediumMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_medium.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Other user message - long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: longMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_long.png',
          screenSize: desktopSize,
        );
      });

      testWidgets('Other user message - super long text', (tester) async {
        await loadTestFonts();
        await runPlatformTest(
          tester: tester,
          message: superLongMessage,
          isMe: false,
          baseGoldenPath: 'goldens/message_actions_other_super_long.png',
          screenSize: desktopSize,
        );
      });
    });
  });
}
