import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/room/providers/room_preview_provider.dart';
import 'package:acter/features/room/widgets/room_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mock_room_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Room Preview Widget', () {
    testWidgets('Shows Chat', (tester) async {
      final roomPreview = MockRoomPreview();
      when(() => roomPreview.roomTypeStr()).thenReturn('chat');
      when(() => roomPreview.name()).thenReturn('Test Chat');
      await tester.pumpProviderWidget(
        overrides: [
          roomPreviewProvider.overrideWith((r, a) async => roomPreview),
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
        ],
        child: const RoomPreviewWidget(roomId: 'roomId'),
      );
      await tester.pump();
      expect(find.text('Test Chat'), findsOneWidget);
    });
  });
}
