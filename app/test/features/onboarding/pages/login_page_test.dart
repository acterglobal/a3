import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
// import 'package:mockito/mockito.dart';

void main() {
  group('login page test', () {
    testWidgets('login ui components are present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginPage(),
          ),
        ),
      );
      final BuildContext context = tester.element(find.byType(LoginPage));
      await tester.pump();
      // check login UI components are present.

      expect(find.byType(SvgPicture), findsOneWidget);

      expect(
        find.text(AppLocalizations.of(context)!.welcomeBack),
        findsOneWidget,
      );
      expect(
        find.text(
          AppLocalizations.of(context)!.loginContinue,
        ),
        findsOneWidget,
      );
      expect(find.byKey(LoginPageKeys.usernameField), findsOneWidget);
      expect(find.byKey(LoginPageKeys.passwordField), findsOneWidget);
      expect(find.byKey(LoginPageKeys.forgotPassBtn), findsOneWidget);
      expect(find.byKey(LoginPageKeys.submitBtn), findsOneWidget);
      expect(
        find.text(
          AppLocalizations.of(context)!.noAccount,
        ),
        findsOneWidget,
      );
      expect(find.byKey(LoginPageKeys.signUpBtn), findsOneWidget);
    });
  });

  testWidgets('text fields validation test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    final BuildContext context = tester.element(find.byType(LoginPage));
    final userNameError =
        find.text(AppLocalizations.of(context)!.emptyUsername);
    final passwordError =
        find.text(AppLocalizations.of(context)!.emptyPassword);
    final submitBtn = find.byKey(LoginPageKeys.submitBtn);
    await tester.tap(submitBtn);
    await tester.pump(const Duration(milliseconds: 100)); // add delay
    expect(userNameError, findsOneWidget);
    expect(passwordError, findsOneWidget);
  });

  // // Not working for some reason.
  // testWidgets('Button triggers navigation to sign up', (tester) async {
  //   final mockObserver = MockNavigatorObserver();
  //   await tester.pumpWidget(
  //     ProviderScope(
  //       child: MaterialApp(
  //         localizationsDelegates: const [
  //           AppLocalizations.delegate,
  //           GlobalMaterialLocalizations.delegate,
  //           GlobalWidgetsLocalizations.delegate,
  //           GlobalCupertinoLocalizations.delegate,
  //         ],
  //         supportedLocales: AppLocalizations.supportedLocales,
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
