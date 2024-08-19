import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrapper_widget.dart';

void main() {
  group('Chat Listing Search', () {
    testWidgets(
      'RoomsList toggle search',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              // Same as before
              isGuestProvider.overrideWithValue(false),
              deviceIdProvider.overrideWithValue('asdf'),
            ],
            child: InActerContextTestWrapper(
              child: RoomsListWidget(
                onSelected: (_) {},
              ),
            ),
          ),
        );
        expect(
          find.byKey(RoomsListWidget.openSearchActionButtonKey),
          findsOneWidget,
        );
        expect(
          find.byKey(RoomsListWidget.searchBarKey),
          findsNothing,
        );
        await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
        await tester.pump();
        // opening the search area
        expect(
          find.byKey(RoomsListWidget.searchBarKey),
          findsOneWidget,
        );
        // close again
        await tester
            .tap(find.byKey(RoomsListWidget.closeSearchActionButtonKey));
        await tester.pump();
        expect(
          find.byKey(RoomsListWidget.searchBarKey),
          findsNothing,
        );
      },
    );
  });
}
