import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/features/preview/widgets/room_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_room_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Room Preview Widget', () {
    testWidgets('Shows Chat', (tester) async {
      final roomPreview = MockRoomPreview();
      when(() => roomPreview.roomTypeStr()).thenReturn('chat');
      when(() => roomPreview.hasAvatar()).thenReturn(false);
      when(() => roomPreview.name()).thenReturn('Test Chat');
      when(() => roomPreview.roomIdStr()).thenReturn('test-chat');
      when(() => roomPreview.joinRuleStr()).thenReturn('invite');
      await tester.pumpProviderWidget(
        overrides: [
          roomPreviewProvider.overrideWith((r, a) async => roomPreview),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
        ],
        child: RoomPreviewWidget(
          roomId: 'roomId',
          onForward: (a, b, c) {},
        ),
      );
      await tester.pump();
      expect(find.text('Test Chat'), findsOneWidget);
    });

    testWidgets('Shows DM', (tester) async {
      final roomPreview = MockRoomPreview();
      when(() => roomPreview.roomTypeStr()).thenReturn('chat');
      when(() => roomPreview.isDirect()).thenReturn(true);
      when(() => roomPreview.hasAvatar()).thenReturn(false);
      when(() => roomPreview.name()).thenReturn('Test Chat');
      when(() => roomPreview.roomIdStr()).thenReturn('test-chat');
      when(() => roomPreview.joinRuleStr()).thenReturn('public');
      await tester.pumpProviderWidget(
        overrides: [
          roomPreviewProvider.overrideWith((r, a) async => roomPreview),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
        ],
        child: RoomPreviewWidget(
          roomId: 'roomId',
          onForward: (a, b, c) {},
        ),
      );
      await tester.pump();
      expect(find.text('Test Chat'), findsOneWidget);
    });

    testWidgets('Shows Space', (tester) async {
      final roomPreview = MockRoomPreview();
      when(() => roomPreview.roomTypeStr()).thenReturn('space');
      when(() => roomPreview.hasAvatar()).thenReturn(false);
      when(() => roomPreview.name()).thenReturn('Test Space');
      when(() => roomPreview.roomIdStr()).thenReturn('test-space');
      when(() => roomPreview.joinRuleStr()).thenReturn('public');
      await tester.pumpProviderWidget(
        overrides: [
          roomPreviewProvider.overrideWith((r, a) async => roomPreview),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
        ],
        child: RoomPreviewWidget(
          roomId: 'roomId',
          onForward: (ca, bb, ac) {},
        ),
      );
      await tester.pump();
      expect(find.text('Test Space'), findsOneWidget);
    });
  });
  testWidgets('Forbidden shows fallback', (tester) async {
    await tester.pumpProviderWidget(
      overrides: [
        roomPreviewProvider.overrideWith(
            (r, a) async => throw '[403 / M_FORBIDDEN] Room not accessible',),
        maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
      ],
      child: RoomPreviewWidget(
        roomId: 'roomId',
        fallbackRoomDisplayName: 'Barcelona',
        onForward: (a, b, c) {},
      ),
    );
    await tester.pump();
    expect(find.text('Barcelona'), findsOneWidget);
  });
}
