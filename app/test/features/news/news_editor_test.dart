import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/pages/add_news_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

import '../../helpers/test_util.dart';

void main() {
  group('Editor close tests', () {
    testWidgets(
      'empty simply closes',
      (tester) async {
        final navigator = MockNavigator();

        when(navigator.canPop).thenReturn(true);
        when(() => navigator.push<void>(any())).thenAnswer((_) async {});

        await tester.pumpProviderWidget(
          overrides: [],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            home: MockNavigatorProvider(
              navigator: navigator,
              child: const AddNewsPage(),
            ),
          ),
        );

        // we are asked to  add a text slide
        final addTextFinder = find.byKey(NewsUpdateKeys.addTextSlide);
        expect(addTextFinder, findsOneWidget);

        // try to go back
        final closeFinder = find.byKey(NewsUpdateKeys.closeEditor);
        expect(closeFinder, findsOneWidget);
        await tester.tap(closeFinder);
        await tester.pumpAndSettle();

        // all was fine

        verify(
          () => navigator.pop<Object?>(null),
        ).called(1);
      },
    );
  });
}
