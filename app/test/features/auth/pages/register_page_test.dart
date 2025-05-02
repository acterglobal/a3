import 'dart:async';

import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/auth/pages/register_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mock_go_router.dart';
import '../../../helpers/test_util.dart';

class MockSdk extends Mock implements ActerSdk {}

class MockClient extends Mock implements Client {}

void main() {
  group('RegisterPage', () {
    late List<Override> providers;
    late MockSdk mockSdk;
    late MockGoRouter mockedGoRouter;
    late MockNavigator mockNavigator;
    setUp(() {
      mockSdk = MockSdk();
      mockedGoRouter = MockGoRouter();
      mockNavigator = MockNavigator();
      SharedPreferences.setMockInitialValues({});
      providers = [
        hasNetworkProvider.overrideWith((ref) => true),
        sdkProvider.overrideWith((ref) => mockSdk),
      ];
      when(mockNavigator.canPop).thenReturn(true);
    });

    testWidgets('shows all required fields', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        navigatorOverride: mockNavigator,
        goRouter: mockedGoRouter,
        overrides: providers,
        child: RegisterPage(),
      );

      // Verify all required fields are present
      expect(find.byKey(RegisterPage.nameField), findsOneWidget);
      expect(find.byKey(RegisterPage.usernameField), findsOneWidget);
      expect(find.byKey(RegisterPage.passwordField), findsOneWidget);
      expect(find.byKey(RegisterPage.tokenField), findsOneWidget);
      expect(find.byKey(RegisterPage.submitBtn), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        navigatorOverride: mockNavigator,
        goRouter: mockedGoRouter,
        overrides: providers,
        child: RegisterPage(),
      );

      // Try to submit without filling any fields

      final submitBtn = find.byKey(RegisterPage.submitBtn);
      await tester.ensureVisible(submitBtn);
      final BuildContext context = tester.element(submitBtn);
      final lang = L10n.of(context);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text(lang.emptyUsername), findsOneWidget);
      expect(find.text(lang.emptyPassword), findsOneWidget);
      expect(find.text(lang.emptyToken), findsOneWidget);
    });

    testWidgets('shows form fields and allows input', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        navigatorOverride: mockNavigator,
        goRouter: mockedGoRouter,
        overrides: providers,
        child: RegisterPage(),
      );

      // Fill in all fields
      await tester.enterText(find.byKey(RegisterPage.nameField), 'Test User');
      await tester.enterText(
        find.byKey(RegisterPage.usernameField),
        'testuser',
      );
      await tester.enterText(
        find.byKey(RegisterPage.passwordField),
        'password123',
      );
      await tester.enterText(find.byKey(RegisterPage.tokenField), 'testtoken');

      // Verify the text was entered correctly
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
      expect(find.text('testtoken'), findsOneWidget);
    });

    group('validates username format', () {
      testWidgets('rejects username with spaces', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.usernameField),
          'invalid username',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Verify validation message
        expect(
          find.text(lang.invalidUsernameFormat, skipOffstage: false),
          findsOneWidget,
        );
      });
      testWidgets('rejects username with non-alphanumeric characters', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.usernameField),
          'invalid:as',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.invalidUsernameFormat, skipOffstage: false),
          findsOneWidget,
        );
      });
    });

    group('validates password format', () {
      testWidgets('accepts password with spaces', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          'password with spaces',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsNothing,
        );
      });
      testWidgets('rejects password ending with space', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          'password with spaces ',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsOneWidget,
        );
      });
      testWidgets('rejects password starting with a space', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          ' password with spaces',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsOneWidget,
        );
      });
    });

    group('goes on correctly', () {
      Future<void> submitValidForm(
        WidgetTester tester, {
        String token = 'testtoken',
      }) async {
        await tester.enterText(find.byKey(RegisterPage.nameField), 'Test User');
        await tester.enterText(
          find.byKey(RegisterPage.usernameField),
          'testuser',
        );
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          'passworD !23',
        );
        await tester.enterText(find.byKey(RegisterPage.tokenField), token);
        final submitBtn = find.byKey(RegisterPage.submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pump();

        expect(
          find.text(lang.invalidUsernameFormat, skipOffstage: false),
          findsNothing,
        );
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsNothing,
        );

        expect(find.text(lang.emptyToken, skipOffstage: false), findsNothing);

        expect(
          find.text(lang.emptyPassword, skipOffstage: false),
          findsNothing,
        );

        expect(
          find.text(lang.emptyUsername, skipOffstage: false),
          findsNothing,
        );
      }

      testWidgets('call register with correct params', (
        WidgetTester tester,
      ) async {
        final completer = Completer<MockClient>();
        when(
          () => mockSdk.register(any(), any(), any(), any()),
        ).thenAnswer((_) async => completer.future);
        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );
        await submitValidForm(tester);

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        expect(submitBtn, findsNothing);
        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsOneWidget,
        );

        // data was passed in correctly
        verify(
          () => mockSdk.register(
            'testuser',
            'passworD !23',
            'Test User',
            'testtoken',
          ),
        ).called(1);
      });

      testWidgets('shared prefs are store correctly', (
        WidgetTester tester,
      ) async {
        final completer = Completer<MockClient>();
        when(
          () => mockSdk.register(any(), any(), any(), any()),
        ).thenAnswer((_) async => completer.future);
        when(() => mockedGoRouter.goNamed(any())).thenAnswer((_) async {});

        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );
        await submitValidForm(tester, token: 'secondary-token');

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        expect(submitBtn, findsNothing);
        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsOneWidget,
        );

        await tester.pump();

        // data was passed in correctly
        verify(
          () => mockSdk.register(
            'testuser',
            'passworD !23',
            'Test User',
            'secondary-token',
          ),
        ).called(1);

        // let it continue
        completer.complete(MockClient());
        await tester.pump();

        // now check the prefs
        final prefs = await sharedPrefs();
        expect(prefs.getString('invitation_token'), 'secondary-token');
      });

      testWidgets('goes on after register correctly', (
        WidgetTester tester,
      ) async {
        SharedPreferences.setMockInitialValues({}); //set values here
        when(
          () => mockedGoRouter.goNamed(
            any(),
            queryParameters: any(named: 'queryParameters'),
            pathParameters: any(named: 'pathParameters'),
            extra: any(named: 'extra'),
            fragment: any(named: 'fragment'),
          ),
        ).thenAnswer((_) async {});

        final client = MockClient();
        final completer = Completer<MockClient>();
        when(
          () => mockSdk.register(any(), any(), any(), any()),
        ).thenAnswer((_) async => completer.future);

        await tester.pumpProviderWidget(
          navigatorOverride: mockNavigator,
          goRouter: mockedGoRouter,
          overrides: providers,
          child: RegisterPage(),
        );
        await submitValidForm(tester);

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        expect(submitBtn, findsNothing);
        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsOneWidget,
        );

        // data was passed in correctly
        verify(
          () => mockSdk.register(
            'testuser',
            'passworD !23',
            'Test User',
            'testtoken',
          ),
        ).called(1);

        // now continuce
        when(
          () => mockSdk.currentClient,
        ).thenReturn(client); // we also must return
        completer.complete(client);
        await tester.pump(); // settle the screen

        expect(
          find.byType(CircularProgressIndicator, skipOffstage: false),
          findsNothing,
        );

        verify(
          () => mockedGoRouter.goNamed(
            any(
              that: equals(Routes.onboarding.name),
            ), // forwarded to the right item
            queryParameters: any(
              named: 'queryParameters',
              that: contains('username'),
            ),
            pathParameters: any(named: 'pathParameters'),
            extra: any(named: 'extra'),
            fragment: any(named: 'fragment'),
          ),
        ).called(1);
      });
    });
  });
}
