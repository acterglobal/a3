import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/chat/widgets/convo_card.dart';
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
      deviceIdProvider.overrideWith((a) async {
        return 'asdf';
      }),
      hasFirstSyncedProvider.overrideWithValue(true),
      ...mockChatRoomProviders(_roomsData),
    ];
    testWidgets('Simple toggle search', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockedProviders,
          child: InActerContextTestWrapper(
            child: RoomsListWidget(onSelected: (_) {}),
          ),
        ),
      );
      expect(
        find.byKey(RoomsListWidget.openSearchActionButtonKey),
        findsOneWidget,
      );
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
      await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
      await tester.pump();
      // opening the search area
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsOneWidget);
      // close again
      await tester.tap(find.byKey(RoomsListWidget.closeSearchActionButtonKey));
      await tester.pump();
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
    });
    testWidgets('Find by title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockedProviders,
          child: InActerContextTestWrapper(
            child: RoomsListWidget(onSelected: (_) {}),
          ),
        ),
      );

      expect(
        find.byKey(RoomsListWidget.openSearchActionButtonKey),
        findsOneWidget,
      );
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
      // -- we see all
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(10),
      );
      await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
      await tester.pump();
      // opening the search area
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsOneWidget);
      await tester.enterText(find.byKey(ActerSearchWidget.searchBarKey), 'CD');
      await tester.pumpProviderScope(times: 2);
      // -- we only see subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(2),
      );
      await tester.tap(
        find.byKey(ActerSearchWidget.clearSearchActionButtonKey),
      );
      await tester.enterText(find.byKey(ActerSearchWidget.searchBarKey), 'E');
      await tester.pumpProviderScope(times: 2);
      // -- we only see subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(3),
      );

      // and we clear
      await tester.tap(
        find.byKey(ActerSearchWidget.clearSearchActionButtonKey),
      );
      // and we close
      await tester.tap(find.byKey(RoomsListWidget.closeSearchActionButtonKey));
      await tester.pumpProviderScope(times: 2);
      // -- we should see all of them again
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(10),
      );
    });

    testWidgets('Find by id', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockedProviders,
          child: InActerContextTestWrapper(
            child: RoomsListWidget(onSelected: (_) {}),
          ),
        ),
      );

      expect(
        find.byKey(RoomsListWidget.openSearchActionButtonKey),
        findsOneWidget,
      );
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
      // -- we see all
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(10),
      );
      await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
      await tester.pump();
      // opening the search area
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsOneWidget);
      await tester.enterText(
        find.byKey(ActerSearchWidget.searchBarKey),
        'mA', // part of one room ID
      );
      await tester.pumpProviderScope(times: 2);
      // -- we only see subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsOneWidget,
      );
      expect(find.text('Room ABC'), findsOne);
      await tester.tap(
        find.byKey(ActerSearchWidget.clearSearchActionButtonKey),
      );
      await tester.enterText(
        find.byKey(ActerSearchWidget.searchBarKey),
        'mD', // part of one room ID
      );
      await tester.pumpProviderScope(times: 2);
      // -- we only see subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsOneWidget,
      );
      expect(find.text('Room DEF'), findsOne);

      // and we clear
      await tester.tap(
        find.byKey(ActerSearchWidget.clearSearchActionButtonKey),
      );
      // and we close
      await tester.tap(find.byKey(RoomsListWidget.closeSearchActionButtonKey));
      await tester.pumpProviderScope(times: 2);
      // -- we should see all of them again
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(10),
      );
    });

    testWidgets('sticky on close', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: mockedProviders,
          child: InActerContextTestWrapper(
            child: RoomsListWidget(onSelected: (_) {}),
          ),
        ),
      );

      expect(
        find.byKey(RoomsListWidget.openSearchActionButtonKey),
        findsOneWidget,
      );
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
      // -- we see all
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsExactly(10),
      );
      await tester.tap(find.byKey(RoomsListWidget.openSearchActionButtonKey));
      await tester.pump();
      // opening the search area
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsOneWidget);
      await tester.enterText(
        find.byKey(ActerSearchWidget.searchBarKey),
        'mA', // part of one room ID
      );
      await tester.pumpProviderScope(times: 2);
      // -- we only see subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsOneWidget,
      );
      expect(find.text('Room ABC'), findsOne);
      await tester.tap(find.byKey(RoomsListWidget.closeSearchActionButtonKey));
      await tester.pumpProviderScope(times: 2);
      expect(find.byKey(ActerSearchWidget.searchBarKey), findsNothing);
      // -- we still only see the subset
      expect(
        find.byType(
          ConvoCard,
          skipOffstage: false, // include off-stage or we don't find all of them
        ),
        findsOneWidget,
      );
      expect(find.text('Room ABC'), findsOne);
    });
  });
}
