import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/auth/pages/login_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('login page test', () {
    testWidgets('login ui components are present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: LoginPage(),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(LoginPage));
      final lang = L10n.of(context);
      await tester.pump();
      // check login UI components are present.

      expect(find.byType(SvgPicture), findsOneWidget);

      expect(find.text(lang.welcomeBack), findsOneWidget);
      expect(find.text(lang.loginContinue), findsOneWidget);
      expect(find.byKey(LoginPageKeys.usernameField), findsOneWidget);
      expect(find.byKey(LoginPageKeys.passwordField), findsOneWidget);
      expect(find.byKey(LoginPageKeys.forgotPassBtn), findsOneWidget);
      expect(find.byKey(LoginPageKeys.submitBtn), findsOneWidget);
      expect(find.text(lang.noProfile), findsOneWidget);
      expect(find.byKey(LoginPageKeys.signUpBtn), findsOneWidget);
    });
  }, skip: 'currently broken');

  testWidgets('text fields validation test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    final BuildContext context = tester.element(find.byType(LoginPage));
    final lang = L10n.of(context);
    final userNameError = find.text(lang.emptyUsername);
    final passwordError = find.text(lang.emptyPassword);
    final submitBtn = find.byKey(LoginPageKeys.submitBtn);
    await tester.tap(submitBtn);
    await tester.pump(const Duration(milliseconds: 100)); // add delay
    expect(userNameError, findsOneWidget);
    expect(passwordError, findsOneWidget);
  }, skip: true);

  // // Not working for some reason.
  // testWidgets('Button triggers navigation to sign up', (tester) async {
  //   final mockObserver = MockNavigatorObserver();
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       child: MaterialApp(
  //         localizationsDelegates: const [
  //           L10n.delegate,
  //           GlobalMaterialLocalizations.delegate,
  //           GlobalWidgetsLocalizations.delegate,
  //           GlobalCupertinoLocalizations.delegate,
  //         ],
  //         supportedLocales: L10n.supportedLocales,
  //         initialRoute: '/login',
  //         routes: <String, WidgetBuilder>{
  //           '/login': (BuildContext context) => const LoginPage(),
  //           '/register': (BuildContext context) => const RegisterPage(),
  //         },
  //         navigatorObservers: [mockObserver],
  //       ),
  //     ),
  //   );
  //   await tester.tap(find.byKey(LoginPageKeys.signUpBtn));
  //   await tester.pumpAndSettle();
  //   // verify(
  //   //   mockObserver.didReplace(
  //   //     oldRoute: anyNamed('oldRoute'),
  //   //     newRoute: anyNamed('newRoute'),
  //   //   ),
  //   // );
  //   expect(find.byType(RegisterPage), findsOneWidget);
  //   expect(find.byType(LoginPage), findsNothing);
  // });
}

// class MockNavigatorObserver extends Mock implements NavigatorObserver {}
