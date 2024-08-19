import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/chat/convo_card.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_chat_providers.dart';
import '../../helpers/test_util.dart';
import '../../helpers/test_wrapper_widget.dart';

const Map<String, AvatarInfo> _roomsData = {
  'roomA': AvatarInfo(uniqueId: 'roomA', displayName: 'Room ABC'),
  'roomB': AvatarInfo(uniqueId: 'roomB', displayName: 'Room BCD'),
  'roomC': AvatarInfo(uniqueId: 'roomC', displayName: 'Room CDE'),
  'roomD': AvatarInfo(uniqueId: 'roomD', displayName: 'Room DEF'),
  'roomE': AvatarInfo(uniqueId: 'roomE', displayName: 'Room EFG'),
  'roomF': AvatarInfo(uniqueId: 'roomF', displayName: 'Room FGH'),
  'roomG': AvatarInfo(uniqueId: 'roomG', displayName: 'Room GHI'),
  'roomH': AvatarInfo(uniqueId: 'roomH', displayName: 'Room HIJ'),
  'roomI': AvatarInfo(uniqueId: 'roomI', displayName: 'Room IJK'),
  'roomJ': AvatarInfo(uniqueId: 'roomJ', displayName: 'Room JKL'),
};

void main() {
  group('Chat Listing Search', () {
    final mockedProviders = [
      // Same as before
      isGuestProvider.overrideWithValue(false),
      deviceIdProvider.overrideWithValue('asdf'),
      hasFirstSyncedProvider.overrideWithValue(true),
      ...mockChatRoomProviders(_roomsData),
    ];
    testWidgets(
      'Simple toggle search',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: mockedProviders,
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
    testWidgets(
      'Search by title',
      (tester) async {
        await tester.pumpWidget(ProviderScope(
          overrides: mockedProviders,
          child: InActerContextTestWrapper(
            child: RoomsListWidget(
              onSelected: (_) {},
            ),
          ),
        ),);

        expect(
          find.byKey(RoomsListWidget.openSearchActionButtonKey),
          findsOneWidget,
        );
        expect(
          find.byKey(RoomsListWidget.searchBarKey),
          findsNothing,
        );
        // -- we see all
        expect(
          find.byType(
            ConvoCard,
            skipOffstage:
                false, // include off-stage or we don't find all of them
          ),
          findsExactly(10),
        );
        await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
        await tester.pump();
        // opening the search area
        expect(
          find.byKey(RoomsListWidget.searchBarKey),
          findsOneWidget,
        );
        await tester.enterText(find.byKey(RoomsListWidget.searchBarKey), 'CD');
        await tester.pumpProviderScope(times: 2);
        // -- we only see subset
        expect(
          find.byType(
            ConvoCard,
            skipOffstage:
                false, // include off-stage or we don't find all of them
          ),
          findsExactly(2),
        );

        // try another
        await tester.enterText(find.byKey(RoomsListWidget.searchBarKey), 'E');
        await tester.pumpProviderScope(times: 2);
        // -- we only see subset
        expect(
          find.byType(
            ConvoCard,
            skipOffstage:
                false, // include off-stage or we don't find all of them
          ),
          findsExactly(3),
        );
      },
    );
  });
}
