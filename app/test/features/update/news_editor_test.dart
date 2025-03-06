import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/news_utils/news_utils.dart';
import 'package:acter/features/news/pages/add_news/add_news_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:path/path.dart' as path;

import '../../helpers/mock_image_provider.dart';
import '../../helpers/test_util.dart';

class _RoutableMainPage extends StatelessWidget {
  static Key gotoBtn = const Key('routable-main-page-to-button');
  final Widget Function(BuildContext) builder;

  const _RoutableMainPage({required this.builder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testing navigation')),
      body: TextButton(
        key: gotoBtn,
        onPressed: () {
          final route = MaterialPageRoute(builder: builder);
          Navigator.of(context).push(route);
        },
        child: const Text('Navigate to details page!'),
      ),
    );
  }
}

void main() {
  group('Editor close tests', () {
    late final MockImagePicker mockImagePicker;
    ImagePicker? prevImagePicker;

    setUpAll(() {
      mockImagePicker = MockImagePicker();
      prevImagePicker = NewsUtils.imagePicker;
      NewsUtils.imagePicker = mockImagePicker;
    });

    tearDownAll(() {
      if (prevImagePicker != null) {
        // restore the imagepicker
        NewsUtils.imagePicker = prevImagePicker!;
      }
    });
    testWidgets('empty simply closes', (tester) async {
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
      final addTextFinder = find.byKey(UpdateKeys.addTextSlide);
      expect(addTextFinder, findsOneWidget);

      // try to go back
      final closeFinder = find.byKey(UpdateKeys.closeEditor);
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      // all was fine

      verify(() => navigator.pop<Object?>(null)).called(1);
    });

    testWidgets('prompt to close and delete draft after confirmation', (
      tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          home: _RoutableMainPage(builder: (c) => const AddNewsPage()),
        ),
      );

      final mainPageBtn = find.byKey(_RoutableMainPage.gotoBtn);
      final addImageFinder = find.byKey(UpdateKeys.addImageSlide);
      final closeFinder = find.byKey(UpdateKeys.closeEditor);
      final confirmCloseFinder = find.byKey(UpdateKeys.confirmDeleteDraft);
      final cancelCloseFinder = find.byKey(UpdateKeys.cancelClose);

      // route to the inner

      expect(mainPageBtn, findsOneWidget);
      await tester.tap(mainPageBtn);
      await tester.pumpAndSettle();

      // we are asked to  add a slide
      expect(addImageFinder, findsOneWidget);

      // mock the imagePicker
      final file = XFile(path.join('foo', 'bar'));
      when(
        () => mockImagePicker.pickImage(source: ImageSource.gallery),
      ).thenAnswer((_) async => file);

      // tap to issue the imagepicker
      await tester.tap(addImageFinder);
      await tester.pumpAndSettle();
      // it is gone now
      expect(addImageFinder, findsNothing);

      // no confirmation dialog
      expect(confirmCloseFinder, findsNothing);

      // try to go back
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      // we didn't go back yet
      expect(mainPageBtn, findsNothing);

      // asked to confirm
      expect(confirmCloseFinder, findsOneWidget);
      expect(cancelCloseFinder, findsOneWidget);

      // let's cancel
      await tester.tap(cancelCloseFinder);
      await tester.pumpAndSettle();

      expect(confirmCloseFinder, findsNothing);
      expect(cancelCloseFinder, findsNothing);
      expect(addImageFinder, findsNothing);

      // we didn't go back yet
      expect(mainPageBtn, findsNothing);

      // let's try again
      expect(closeFinder, findsOneWidget);
      await tester.tap(closeFinder);
      await tester.pumpAndSettle();

      // this time we confirm
      expect(confirmCloseFinder, findsOneWidget);
      expect(cancelCloseFinder, findsOneWidget);
      await tester.tap(confirmCloseFinder);
      await tester.pumpAndSettle();

      // this time we were popped.
      expect(mainPageBtn, findsOneWidget);

      // let's open the add page again and confirm
      // the draft is gone
      await tester.tap(mainPageBtn);
      await tester.pumpAndSettle();

      // we are asked to  add a slide
      expect(addImageFinder, findsOneWidget);
      // perfect!
    });
  });
}
