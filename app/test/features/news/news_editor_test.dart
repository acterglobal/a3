import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/pages/add_news_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../../helpers/navigation_mock.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Editor close tests', () {
    testWidgets(
      'empty simply closes',
      (tester) async {
        final mockObserver = MockNavigatorObserver();

        await tester.pumpProviderWidget(
          overrides: [],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            home: RoutableMainPage(
              builder: (_) => const SizedBox(
                width: 300,
                height: 600,
                child: Scaffold(body: AddNewsPage()),
              ),
            ),
            navigatorObservers: [mockObserver],
          ),
        );

        // route to
        final gotoFinder = find.byKey(RoutableMainPage.gotoBtn);
        expect(gotoFinder, findsOneWidget);
        await tester.tap(gotoFinder);
        await tester.pumpAndSettle();

        // add a text slide
        final addTextFinder = find.byKey(NewsUpdateKeys.addTextSlide);
        expect(addTextFinder, findsOneWidget);
        await tester.tap(addTextFinder);
        await tester.pumpAndSettle();
        expect(addTextFinder, findsNothing);

        // try to go back
        final closeFinder = find.byKey(NewsUpdateKeys.closeEditor);
        expect(closeFinder, findsOneWidget);
        await tester.tap(closeFinder);
        await tester.pumpAndSettle();

        // all was fine
        verify(mockObserver.didPop(any!, any));
      },
      skip: true, // appflowy is currently broken
    );
  });
}
