import 'package:acter/common/utils/constants.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:convenient_test/convenient_test.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:acter/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

const registrationToken = String.fromEnvironment(
  'REGISTRATION_TOKEN',
  defaultValue: '',
);

void main() {
  convenientTestMain(MyConvenientTestSlot(), () {
    group('smoketests', () {
      tTestWidgets('kyra login test', (t) async {
        await t.login('kyra');
      });
    });
    //   group('smoketests', () {
    //     tTestWidgets('login test', (t) async {
    //       // await t.get(HomePageMark.fetchFruits).tap();
    //       await find.text('HomePage').should(findsOneWidget);
    //       await find.text('You chose nothing').should(findsOneWidget);

    //       await find.text('Cherry').tap();
    //       await find.text('You chose: Cherry').should(findsOneWidget);

    //       await t.tester.scrollUntilVisible(find.text('Orange'), 100);
    //       await find.text('Orange').tap();
    //       await find.text('You chose: Cherry, Orange').should(findsOneWidget);

    //       // await t.get(HomePageMark.fab).tap();
    //       await find.text('HomePage').should(findsNothing);
    //       await find.text('SecondPage').should(findsOneWidget);
    //       await find.text('See fruits: Cherry, Orange').should(findsOneWidget);

    //       await t.pageBack();
    //       await find.text('HomePage').should(findsOneWidget);
    //     });

    //     tTestWidgets('deliberately failing test', (t) async {
    //       expect(1, 0, reason: 'this expect should deliberately fail');
    //     });

    //     tTestWidgets('deliberately flaky test', (t) async {
    //       final shouldFailThisTime = !_deliberatelyFlakyTestHasRun;
    //       _deliberatelyFlakyTestHasRun = true;

    //       // await t.get(HomePageMark.fetchFruits).tap();

    //       if (shouldFailThisTime) {
    //         await find.text('NotExistString').should(findsOneWidget);
    //       } else {
    //         await find.text('Apple').should(findsOneWidget);
    //       }
    //     });

    //     tTestWidgets('navigation', (t) async {
    //       await t.visit('/second');
    //       await find.text('HomePage').should(findsNothing);
    //       await find.text('SecondPage').should(findsOneWidget);

    //       // you can also assert route names
    //       await t.routeName().shouldEquals('/second');

    //       await t.pageBack();
    //       await find.text('HomePage').should(findsOneWidget);
    //       await find.text('SecondPage').should(findsNothing);
    //     });

    //     tTestWidgets('find by icon', (t) async {
    //       await find.byIcon(Icons.done).should(findsOneWidget);
    //     });

    //     tTestWidgets('golden test', (t) async {
    //       await find.text('HomePage').should(findsOneWidget);

    //       await find
    //           .byType(MaterialApp)
    //           .should(matchesGoldenFile('goldens/sample_golden.png'));
    //     });

    //     tTestWidgets('deliberately failed golden test', (t) async {
    //       await t.visit('/random');
    //       await find.text('RandomPage').should(findsOneWidget);

    //       // await find.get(RandomPageMark.randomText).should(
    //       //     matchesGoldenFile('goldens/deliberately_failed_golden.png'));

    //       // let's assert something else
    //       await find.textContaining('Random Height').should(findsOneWidget);
    //       await find.textContaining('Height').should(findsOneWidget);
    //     });

    //     tTestWidgets('custom logging and snapshotting', (t) async {
    //       // suppose you do something normal...
    //       await find.text('HomePage').should(findsOneWidget);

    //       // then you want to log and snapshot
    //       final log = t.log('HELLO', 'Just a demonstration of custom logging');
    //       await log.snapshot();
    //     });

    //     tTestWidgets('custom commands', (t) async {
    //       await t.freshAccount();
    //     });

    //     tTestWidgets('sections', (t) async {
    //       t.section('sample section one');

    //       // do something
    //       // await t.get(HomePageMark.fetchFruits).tap();
    //       await find.text('Apple').tap();
    //       await find.text('Banana').tap();
    //       await find.text('Cherry').tap();

    //       t.section('sample section two');

    //       // do something
    //       await find.text('Apple').tap();
    //       await find.text('Banana').tap();
    //       await find.text('Cherry').tap();
    //       await find.text('HomePage').should(findsOneWidget);
    //     });

    //     tTestWidgets('timer page', (t) async {
    //       await t.visit('/timer');

    //       for (var iter = 0; iter < 5; ++iter) {
    //         final log = t.log('HELLO', 'Wait a second to have a look (#$iter)');
    //         await log.snapshot(name: 'before');

    //         final stopwatch = Stopwatch()..start();
    //         while (stopwatch.elapsed < const Duration(seconds: 1)) {
    //           await t.tester.pump();
    //         }

    //         await log.snapshot(name: 'after');
    //       }

    //       await t.pageBack();
    //     });

    //     tTestWidgets('enter and append text', (t) async {
    //       await t.visit('/text_field');

    //       await find.byType(TextField).enterTextWithoutReplace('first');
    //       await find.text('first').should(findsOneWidget);

    //       await find.byType(TextField).enterTextWithoutReplace(' second');
    //       await find.text('first second').should(findsOneWidget);
    //     });

    //     group('zoom page', () {
    //       tTestWidgets('single finger drag', (t) async {
    //         await t.visit('/zoom');
    //         await t.pumpAndSettle();

    //         // await find
    //         //     .get(ZoomPageMark.palette)
    //         //     .should(matchesGoldenFile('goldens/zoom_page_drag_before.png'));

    //         // await find.get(ZoomPageMark.palette).drag(const Offset(0, -50));

    //         // await find
    //         //     .get(ZoomPageMark.palette)
    //         //     .should(matchesGoldenFile('goldens/zoom_page_drag_after.png'));

    //         // alternative approach
    //         // await t.tester.drag(find.get(ZoomPageMark.palette), const Offset(0, -50));

    //         // sample logging
    //         // await t.tester.pumpAndSettle();
    //         // await t.log('HELLO', 'look at it').snapshot();
    //       });

    //       tTestWidgets('double finger zooming', (t) async {
    //         await t.visit('/zoom');

    //         // await find
    //         //     .get(ZoomPageMark.palette)
    //         //     .should(matchesGoldenFile('goldens/zoom_page_zoom_before.png'));

    //         // await find.get(ZoomPageMark.palette).multiDrag(
    //         //       firstDownOffset: const Offset(0, -30),
    //         //       secondDownOffset: const Offset(0, 30),
    //         //       firstFingerOffsets: const [
    //         //         Offset(0, -20),
    //         //         Offset(0, -20),
    //         //         Offset(0, -10)
    //         //       ],
    //         //       secondFingerOffsets: const [
    //         //         Offset(0, 20),
    //         //         Offset(0, 20),
    //         //         Offset(0, 10)
    //         //       ],
    //         //       logMove: true,
    //         //     );

    //         // await find
    //         //     .get(ZoomPageMark.palette)
    //         //     .should(matchesGoldenFile('goldens/zoom_page_zoom_after.png'));
    //       });
    //     });
    //   });

    //   group('some other test group', () {
    //     tTestWidgets('empty test', (t) async {});

    //     group('sample sub-group', () {
    //       tTestWidgets('another empty test', (t) async {});

    //       group('sample sub-sub-group', () {
    //         tTestWidgets('yet another empty test', (t) async {});
    //       });
    //     });
    //   });
  });
}

var _deliberatelyFlakyTestHasRun = false;

class MyConvenientTestSlot extends ConvenientTestSlot {
  @override
  Future<void> appMain(AppMainExecuteMode mode) async =>
      startFreshTestApp('test-example');

  @override
  BuildContext? getNavContext(ConvenientTest t) => rootNavKey.currentContext;
}

extension on ConvenientTest {
  // Future<void> freshAccount() async {
  //   final newId = const Uuid().v4().toString();
  //   startFreshTestApp(newId);
  //   return await register(newId);
  // }

  Future<void> login(String username) async {
    String passwordText;
    if (registrationToken.isNotEmpty) {
      passwordText = '$registrationToken:$username';
    } else {
      passwordText = username;
    }

    Finder skip = find.byKey(Keys.skipBtn);
    await skip.should(findsOneWidget);

    await skip.tap();

    Finder login = find.byKey(Keys.loginBtn);
    await login.should(findsOneWidget);

    await login.tap();

    Finder user = find.byKey(LoginPageKeys.usernameField);
    await user.should(findsOneWidget);

    await user.enterTextWithoutReplace(username);

    Finder password = find.byKey(LoginPageKeys.passwordField);
    await password.should(findsOneWidget);

    await password.enterTextWithoutReplace(passwordText);

    Finder submitBtn = find.byKey(LoginPageKeys.submitBtn);
    await submitBtn.should(findsOneWidget);
    await submitBtn.tap();
    // we should see a main navigation, either at the side (desktop) or the bottom (mobile/tablet)
    await find.byKey(Keys.mainNav).should(findsOneWidget);
  }
}

Future<void> startFreshTestApp(String key) async {
  await ActerSdk.resetSessionsAndClients(key);
  await app.startAppInner(ConvenientTestWrapperWidget(child: app.makeApp()));
}
